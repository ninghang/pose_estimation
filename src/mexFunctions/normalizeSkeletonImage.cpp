#include "opencv2/opencv.hpp"
#include "MxArray.hpp"
#include "mex.h"
#include <stdio.h>
#include <stdlib.h>

/*
 * Print usuage of the function
 */
void printUsage()
{
  mexPrintf(
      "Usage: [NormSkelPoints,image] = normSkeletonPoints(skelPoints,imagePath)");
}

/*
 * Check input and output arguments
 */
void checkInputOutput(int nrhs, int nlhs, const mxArray* prhs[])
{
  /* check proper input and output */
  if (nrhs != 2)
  {
    printUsage();
    mexErrMsgIdAndTxt("MATLAB:normSkeletonPoints:invalidNumInputs",
        "Two input required.");
  }
  else if (nlhs != 2)
  {
    printUsage();

    mexErrMsgIdAndTxt("MATLAB:normSkeletonPoints:maxlhs",
        "Two output arguments.");
  }
  else if (!mxIsChar(prhs[1]))
  {
    printUsage();

    mexErrMsgTxt("The second input must be a string");
  }
  else if (mxIsNumeric(prhs[0]) && mxGetNumberOfDimensions(prhs[0]) != 2)
  {
    printUsage();

    mexErrMsgTxt("Skeleton points must be a 2D matrix");
  }
}

/*
 * Load source image
 */
void loadImage(const mxArray* prhs[], cv::Mat& im)
{
  // load source image
  std::string imFile = MxArray(prhs[1]).toString(); //string
  im = cv::imread(imFile);
  if (!im.data)
    mexErrMsgTxt("Unable to load image");
  cv::cvtColor(im, im, CV_BGR2RGB); // TODO remove if not used in matlab mex functions
  return;
}

/*
 * Rotate and translate to normalized skeletons points
 *  compute coorindate frame of the human rectangle - size, center, rotation
 *  rotate the image by the center so that the human is up-right
 *  crop the image at the rotated human image
 *  project points to the new human image
 */
void normalizeSkeletonImage(cv::Mat points, cv::Mat im, cv::Mat& cropped,
    cv::Mat& tfPoints)
{
  const int shift = 50; // make sure to see the whole parts on the edge

  cv::Point2d head_location;
  head_location.x = points.at<double>(0, 0);
  head_location.y = points.at<double>(0, 1);

  cv::Point2d image_center(im.cols / 2, im.rows / 2); // NOTE: x goes along columns! TODO

  // rectangle coordinate frame
  cv::Point2d imFrameY = head_location - image_center;
  imFrameY = imFrameY * (1 / norm(imFrameY)); // unit direction vector: image center -> head location
  cv::Point2d imFrameX(imFrameY.y, imFrameY.x * -1);

  // project skeleton points into rectangle frame
  cv::Mat projection_matrix = cv::Mat::zeros(2, 1, CV_64FC2);
  projection_matrix.at<cv::Point2d>(0, 0) = imFrameY;
  projection_matrix.at<cv::Point2d>(1, 0) = imFrameX;
  projection_matrix = projection_matrix.reshape(1).t();
  cv::Mat projected_points = points * projection_matrix;

  // human rectangle: size
  cv::Mat pnts_x = projected_points.col(0);
  cv::Mat pnts_y = projected_points.col(1);
  double max_x, min_x, max_y, min_y;
  minMaxLoc(pnts_x, &min_x, &max_x);
  minMaxLoc(pnts_y, &min_y, &max_y);
  double rect_width = max_y - min_y;
  double rect_height = max_x - min_x;
  cv::Size2f rect_size(rect_width + shift, rect_height + shift);

  // human rectangle: center
  double projHeadX = pnts_x.at<double>(0, 0);
  double projHeadY = pnts_y.at<double>(0, 0);
  // project points back to image frame
  cv::Point2d p1 = (max_x - projHeadX) * imFrameY
      + (max_y - projHeadY) * imFrameX; // top-left
  cv::Point2d p2 = (min_x - projHeadX) * imFrameY
      + (min_y - projHeadY) * imFrameX; // bottom-right
  cv::Point2d rect_center = (p1 + p2) * .5 + head_location; // rectangle center in image frame

  // human rectangle: rotation
  cv::Point2d vertical_norm(0, -1);
  double angle_rad = acos(imFrameY.dot(vertical_norm));
  double angle_deg = angle_rad / CV_PI * 180;
  cv::Mat m1, m2;
  m1.push_back(cv::Point3d(vertical_norm.x, vertical_norm.y, 0));
  m2.push_back(cv::Point3d(imFrameY.x, imFrameY.y, 0));
  cv::Mat cross_mat = m1.cross(m2);
  if (cross_mat.at<cv::Point3d>(0, 0).z < 0)
    // rotate counter-clockwise
    angle_deg *= -1;

  // rotate image by the center of the rectangle
  cv::Mat rotated;
  cv::Mat M = getRotationMatrix2D(rect_center, angle_deg, 1.0);
  cv::warpAffine(im, rotated, M, im.size(), cv::INTER_CUBIC); // TODO: set image roi

  // crop human image at the rectangle
  getRectSubPix(rotated, rect_size, rect_center, cropped); // crop

  // transformed points
  cv::Point2d origin;
  origin.x = rect_center.x - rect_size.width / 2;
  origin.y = rect_center.y - rect_size.height / 2;

  cv::transform(points.reshape(2), tfPoints, M);
  tfPoints = tfPoints.reshape(1);

  tfPoints.col(0) = tfPoints.col(0) - origin.x;
  tfPoints.col(1) = tfPoints.col(1) - origin.y;
  return;
}

/*
 * Matlab mex function
 * Usage: [NormSkelPoints,image] = normSkeletonPoints(skelPoints,imageName)
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  cv::Mat im, cropped, tfPoints;

  checkInputOutput(nrhs, nlhs, prhs); // check proper input and output

  loadImage(prhs, im); // load source image

  cv::Mat points = MxArray(prhs[0]).toMat(); // load skeleton points

  normalizeSkeletonImage(points, im, cropped, tfPoints);

  plhs[0] = MxArray(tfPoints); // transformed skeleton points
  plhs[1] = MxArray(cropped); // transformed human image

  return;
}
