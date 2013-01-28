//
//  Vector.cpp
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "Vector.h"
#include <cmath>

Vector::Vector() : x(0), y(0)
{
}

Vector::Vector(double newX, double newY) : x(newX), y(newY)
{
}

Vector::Vector(double array[]) : x(array[0]), y(array[1])
{
}

Vector::Vector(float array[]) : x(array[0]), y(array[1])
{
}

Vector::Vector(int array[]) : x(array[0]), y(array[1])
{
}

Vector::~Vector()
{
    
}

Vector Vector::operator+(const Vector& rhs) const
{
    return Vector(x + rhs.x, y + rhs.y);
}

Vector Vector::operator-(const Vector& rhs) const
{
    return Vector(x - rhs.x, y - rhs.y);
}

Vector Vector::operator*(const double factor) const
{
    return Vector(x * factor, y * factor);
}

Vector Vector::operator/(const double factor) const
{
    return Vector(x / factor, y / factor);
}

double Vector::operator[](const int index) const
{
	switch (index) {
		case VECTOR_X:
			return x;
			break;
		default:
			return y;
			break;
	}
}

double& Vector::operator[](const int index)
{
	switch (index) {
		case VECTOR_X:
			return x;
			break;
		default:
			return y;
			break;
	}
}

void Vector::translateBy(const Vector& rhs)
{
	x += rhs.x;
	y += rhs.y;
}

void Vector::scaleBy(const double factor)
{
	x *= factor;
	y *= factor;
}

void Vector::normalize()
{
	double length = sqrt(x * x + y * y);
	if (length > 0.0001) {
		x /= length;
		y /= length;
	}
}

Vector& Vector::normalized()
{
	double length = sqrt(x * x + y * y);
	if (length > 0.0001) {
		x /= length;
		y /= length;
	}
	return *this;
}

double Vector::normalizeAndReturn()
{
	double length = sqrt(x * x + y * y);
	if (length > 0.0001) {
		x /= length;
		y /= length;
	}
	return length;
}

void Vector::zero()
{
	x = y = 0.0;
}

double Vector::getLength() const
{
	return sqrt(x * x + y * y);
}

double Vector::getSquaredLength() const
{
	return (x * x + y * y);
}

double Vector::Dot(const Vector& rhs) const
{
	return (x * rhs.x + y * rhs.y);
}

void Vector::toArray(double array[]) const
{
	array[0] = x;
	array[1] = y;
}

void Vector::toArray(float array[]) const
{
	array[0] = (float)x;
	array[1] = (float)y;
}

void Vector::fromArray(double array[])
{
	x = array[0];
	y = array[1];
}

void Vector::fromArray(float array[])
{
	x = array[0];
	y = array[1];
}

void Vector::rotateX(const double degrees) {
	radianRotateX(degrees * DEG_TO_RAD);
}

void Vector::rotateY(const double degrees) {
	radianRotateY(degrees * DEG_TO_RAD);
}

void Vector::radianRotateX(const double radians) {
	double cosAngle = cos(radians);
	double sinAngle = sin(radians);
	double origY = y;
	y =	y * cosAngle - z * sinAngle;
	z = origY * sinAngle + z * cosAngle;
}

void Vector::radianRotateY(const double radians) {
	double cosAngle = cos(radians);
	double sinAngle = sin(radians);
	double origX = x;
	x =	x * cosAngle + z * sinAngle;
	z = z * cosAngle - origX * sinAngle;
}

Vector Vector::interpolate1(const Vector& endPoint, const double t) const
{
	return Vector(x + t * (endPoint.x - x),
		          y + t * (endPoint.y - y));
}

Vector Vector::interpolate2(const Vector& midControl, const Vector& endControl, const double t) const
{
    Vector left = this->interpolate1(midControl, t);
	Vector right = midControl.interpolate1(endControl, t);
	return left.interpolate1(right, t);
}

Vector Vector::interpolate3(const Vector& leftControl, const Vector& rightControl, const Vector& endControl, const double t) const
{
    Vector begin = this->interpolate1(leftControl, t);
	Vector mid = leftControl.interpolate1(rightControl, t);
	Vector end = rightControl.interpolate1(endControl, t);
	return begin.interpolate2(mid, end, t);
}
