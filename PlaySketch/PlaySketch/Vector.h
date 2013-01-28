//
//  Vector.h
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#ifndef VECTOR_H
#define VECTOR_H

#ifndef M_PI
#define M_PI 3.141592653589793
#endif
#ifndef DEG_TO_RAD
#define DEG_TO_RAD 0.017453292519943
#endif

#define VECTOR_X 0
#define VECTOR_Y 1

class Vector
{
public:
	Vector();
	Vector(double x, double y);
	Vector(double[]);
	Vector(float[]);
	Vector(int[]);
    
	virtual ~Vector();
    
	double x;
	double y;
	double z;

	Vector operator+(const Vector& rhs) const;
	Vector operator-(const Vector& rhs) const;
    
	Vector operator*(const double factor) const;
	Vector operator/(const double factor) const;
    
	double operator[](const int index) const;

	double& operator[](const int index);

    void translateBy(const Vector& rhs);

	void scaleBy(const double factor);

	void normalize();

	Vector& normalized();

	double normalizeAndReturn();
 
	void zero();

	double getLength() const;

	double getSquaredLength() const;

	double Dot(const Vector& rhs) const;
   
	void toArray(double array[]) const;
	
	void toArray(float array[]) const;
 
	void fromArray(double array[]);
	
	void fromArray(float array[]);
 
	void rotateX(const double degrees);
	void rotateY(const double degrees);

	void radianRotateX(const double radians);
	void radianRotateY(const double radians);

	void rotateAxis(const Vector& axis, const double degrees);

	Vector interpolate1(const Vector& endPoint, const double t) const;
    
	Vector interpolate2(const Vector& midControl, const Vector& endControl, const double t) const;
    
	Vector interpolate3(const Vector& leftControl, const Vector& rightControl, const Vector& endControl, const double t) const;
    
};

#endif
