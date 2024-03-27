#include <MovingAverages.mqh>


// pass an array 

double      CalculateStandardDeviation(int position, int periods, const double &price[]) {

   double sum = 0;
   bool price_as_series = ArrayGetAsSeries(price);
   if (price_as_series) ArraySetAsSeries(price, false);
   double mean = SimpleMA(position, periods, price);
   
   if (position >= periods) {
      for (int i = 0; i < periods; i++) {
         double x_i = price[position-i];
         double diff = MathPow(x_i - mean, 2);
         sum += diff;
      }
   }
   
   double sdev = MathSqrt(sum / (periods-1)); 
   return sdev;   
}


double      CalculateSkew(int position, int periods, const double &price[]) {
   
   double sum = 0;
   double standard_deviation = CalculateStandardDeviation(position, periods, price);
   bool price_as_series = ArrayGetAsSeries(price);
   if (price_as_series) ArraySetAsSeries(price, false);
   double mean = SimpleMA(position, periods, price);
   
   if (position >= periods) {
      for (int i = 0; i < periods; i++) {
         double x_i = price[position - i];
         double diff = MathPow(x_i - mean, 3);
         sum += diff;
      }   
      
      
   }
   if (standard_deviation == 0) {
         return 0;
      }
   double skew = (sum) / ((periods - 1) * (MathPow(standard_deviation, 3)));
   return skew;
}

double      CalculateSpread(int position, int periods, const double &price[]) {
   // for univariate mean reversion 
   bool array_as_series = ArrayGetAsSeries(price);
   if (array_as_series) ArraySetAsSeries(price, false);
   
   double price_reference = price[position];
   
   double mean = SimpleMA(position, periods, price);
   
   double spread = price_reference - mean;
   return spread;
}


double      CalculateStandardScore (int position, const int period, const double &price[]) {
   /*
   Normalizing with Z Score
   */
   bool array_as_series = ArrayGetAsSeries(price);
   if (array_as_series) ArraySetAsSeries(price, false);
   
   double   mu       = SimpleMA(position, period, price);
   double   sigma    = CalculateStandardDeviation(position,period, price);
   double   spread   = price[position];
   
   if (sigma == 0) return 0; 
   
   double z = (spread - mu) / sigma;
   return z;
}

