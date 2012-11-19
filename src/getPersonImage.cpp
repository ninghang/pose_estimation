#include "opencv2/opencv.hpp"
#include <iostream>
#include <stdio.h>
#include <time.h>
#include <sstream>

using namespace cv;
using namespace std;

int main(int, char** argv)
{
  string res_folder = "../res/";

  bool isSave = false;
  string out_folder = res_folder + "human_images/";
  string frame_folder = res_folder + "frame_images/";
  string data_file = res_folder + "data.xml";
  Point2d image_center(512,486); // NOTE: x goes along columns!

  // read data.xml
  FileStorage fs(data_file,FileStorage::READ);
  if( !fs.isOpened() )
  {
    cout << "Error: " << data_file << ": No such file" << endl;
    return -1;
  }

  Mat frame_id, human_locations, human_templates;
  fs["human_locations"] >> human_locations;
  fs["human_templates"] >> human_templates;
  fs["frame_id"] >> frame_id;

  for (int i=0;i<frame_id.rows;i++)
  {
//    cout << i << endl;

    Point2d human_location = human_locations.at<Point2d>(i,0);
    Mat human_template = human_templates.row(i);
//    cout << "human_location" << human_location << endl;

    char image_file[100];
    sprintf(image_file,"%s%04d.jpg",frame_folder.c_str(),frame_id.at<int>(i,0));
    Mat im = imread(image_file);
    if (!im.data && i == 0)
    {
      cout << "Error: " << image_file << " image not found" << endl;
      return -1;
    }

    // direction vector from image center to human location
    Point2d direction = human_location - image_center;
    direction = direction * (1 / norm(direction)); // direction vector: image center -> human location
//    cout << "direction vector: " << direction << endl;
//    cout << "image center: " << image_center << endl;


    // project template points onto direction vector
    Mat projection_matrix = Mat::zeros(2,1,CV_64FC2);
    projection_matrix.at<Point2d>(0,0) = direction;
    Point2d direction2 = direction;
    direction2.x = direction2.x * -1;
    projection_matrix.at<Point2d>(1,0) = direction2;
    projection_matrix = projection_matrix.reshape(1).t();
    human_template = human_template.reshape(1,human_template.cols);
    Mat projected_temlate = human_template * projection_matrix;
//    cout << "projection_matrix: " << projection_matrix << endl;
//    cout << "projected_temlate: " << projected_temlate << endl;


    // compute width and height of bounding rectangle
    Mat pnts_x = projected_temlate.col(0);
    Mat pnts_y = projected_temlate.col(1);
    double max_x, min_x, max_y, min_y;
    minMaxLoc(pnts_x,&min_x,&max_x);
    minMaxLoc(pnts_y,&min_y,&max_y);
    double rect_width = max_y - min_y;
    double rect_height = max_x - min_x;
//    cout << "w:" << rect_width << ", h:" << rect_height << endl;


    // compute center of bounding rectangle
    double scale_human = (max_x + min_x) / 2;
    double scale_image_center = image_center.dot(direction);
    double scale = scale_human - scale_image_center;
    Point2f rect_center = scale * direction + image_center;
//    cout << "scale_human: " << scale_human << endl;
//    cout << "scale_image_center: " << scale_image_center << endl;
//    cout << "human center: " << rect_center << endl;


    // compute rotation of bounding rectangle
    Point2d vertical_norm(0,-1);
    double angle_rad = acos(direction.dot(vertical_norm));
    double angle_deg = angle_rad / CV_PI * 180;
    Mat m1, m2;
    m1.push_back(Point3d(vertical_norm.x,vertical_norm.y,0));
    m2.push_back(Point3d(direction.x,direction.y,0));
    Mat cross_mat = m1.cross(m2);
    if (cross_mat.at<Point3d>(0,0).z < 0) // rotate counter-clockwise
      angle_deg *= -1;
//    cout << "=degree= " << angle_deg << endl;


    // construct rotated rectangle
    RotatedRect rot_rect(rect_center, Size2f(rect_width,rect_height), angle_deg);


    // crop human image
    Mat rotated, cropped;
    Rect brect = rot_rect.boundingRect();
    Mat M = getRotationMatrix2D(rot_rect.center, angle_deg, 1.0);
//    Mat imroi = im(brect);
    warpAffine(im, rotated, M, im.size(), INTER_CUBIC); // TODO: set image roi
    getRectSubPix(rotated, rot_rect.size, rot_rect.center, cropped); // crop

    if (isSave)
    {
      char out_name[100];
      sprintf(out_name,"%s%04d_%d.jpg",out_folder.c_str(),frame_id.at<int>(i,0),i+1);
      imwrite(out_name,cropped);
    }
    else
    {
      // plot everything
      Mat view = im.clone();
      Point2f vertices[4];
      rot_rect.points(vertices);
      for (int j = 0; j < 4; j++)
        line(view, vertices[j], vertices[(j+1)%4], Scalar(0,255,0));
      circle(view, image_center, 5,Scalar(0,0,255));
      circle(view, human_location, 5,Scalar(255,255,0));
      line(view,image_center,rect_center,Scalar(0,0,255));
      namedWindow("view",CV_WINDOW_NORMAL);
      imshow("view",view);
      namedWindow("view2",CV_WINDOW_NORMAL);
      imshow("view2",cropped);
      waitKey(0);
    }
  }
}
