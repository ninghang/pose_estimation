#include "opencv2/opencv.hpp"
#include "MxArray.hpp"
#include "mex.h"
#include <stdio.h>
#include <stdlib.h>

/*
 * Check input and output arguments
 */
void checkInputOutput(int nrhs, int nlhs, const mxArray* prhs[])
{
  /* check proper input and output */
  if (nrhs != 2)
    mexErrMsgIdAndTxt("MATLAB:normSkeletonPoints:invalidNumInputs",
        "Two input required.");
  else if (nlhs != 2)
    mexErrMsgIdAndTxt("MATLAB:normSkeletonPoints:maxlhs",
        "Two output arguments.");
  else if (!mxIsChar(prhs[1]))
    mexErrMsgTxt("The second input must be a string");
  else if (mxIsNumeric(prhs[0]) && mxGetNumberOfDimensions(prhs[0]) != 2)
    mexErrMsgTxt("Skeleton points must be a 2D matrix");
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
 */
void normalizeSkeletonImage(cv::Mat points, cv::Mat im, cv::Mat& cropped,
    cv::Mat& tfPoints)
{
  const int shift = 50;
  cv::Point2d head_location;
  head_location.x = points.at<double>(0, 0);
  head_location.y = points.at<double>(0, 1);

  cv::Point2d image_center(im.cols / 2, im.rows / 2); // NOTE: x goes along columns! TODO

  // direction vector from image center to head location
  cv::Point2d direction = head_location - image_center;
  direction = direction * (1 / norm(direction)); // unit direction vector: image center -> human location

  // project skeleton points onto directional vector
  cv::Mat projection_matrix = cv::Mat::zeros(2, 1, CV_64FC2);
  projection_matrix.at<cv::Point2d>(0, 0) = direction;
  cv::Point2d direction2(direction.y, direction.x * -1);
  projection_matrix.at<cv::Point2d>(1, 0) = direction2;
  projection_matrix = projection_matrix.reshape(1).t();
  cv::Mat projected_points = points * projection_matrix;

  // width and height of human rectangle
  cv::Mat pnts_x = projected_points.col(0);
  cv::Mat pnts_y = projected_points.col(1);
  double max_x, min_x, max_y, min_y;
  minMaxLoc(pnts_x, &min_x, &max_x);
  minMaxLoc(pnts_y, &min_y, &max_y);
  double rect_width = max_y - min_y;
  double rect_height = max_x - min_x;

  // center of the human rectangle
  double scale_human = (max_x + min_x) / 2;
  double scale_image_center = image_center.dot(direction);
  double scale = scale_human - scale_image_center;
  cv::Point2f rect_center = scale * direction + image_center;

  // rotation of the human rectangle
  cv::Point2d vertical_norm(0, -1);
  double angle_rad = acos(direction.dot(vertical_norm));
  double angle_deg = angle_rad / CV_PI * 180;
  cv::Mat m1, m2;
  m1.push_back(cv::Point3d(vertical_norm.x, vertical_norm.y, 0));
  m2.push_back(cv::Point3d(direction.x, direction.y, 0));
  cv::Mat cross_mat = m1.cross(m2);
  if (cross_mat.at<cv::Point3d>(0, 0).z < 0)
    // rotate counter-clockwise
    angle_deg *= -1;

  // construct rotated human rectangle that fit the personen
  // enlarged with a shift
  cv::RotatedRect rot_rect(rect_center,
      cv::Size2f(rect_width + shift, rect_height + shift), angle_deg);

  // rotate image by the center of the rectangle
  cv::Mat rotated;
  cv::Mat M = getRotationMatrix2D(rot_rect.center, angle_deg, 1.0);
  cv::warpAffine(im, rotated, M, im.size(), cv::INTER_CUBIC); // TODO: set image roi

  // crop human image at the rectangle
  getRectSubPix(rotated, rot_rect.size, rot_rect.center, cropped); // crop

  // transformed points
  cv::Point2d origin;
  origin.x = rot_rect.center.x - rot_rect.size.width / 2;
  origin.y = rot_rect.center.y - rot_rect.size.height / 2;

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
