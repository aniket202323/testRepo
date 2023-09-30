/*
Example Call
select dbo.fnCMN_SampleSizeLookUp(5, 'd2')
select dbo.fnCMN_SampleSizeLookUp(5, 'd3')
select dbo.fnCMN_SampleSizeLookUp(30, 'C4')
*/
CREATE FUNCTION dbo.fnCMN_SampleSizeLookUp(@SubGroupSize INT, @Method nVarChar(2))
 	 returns FLOAT
as
BEGIN
  -- Method 1 = d2        Method 2 = C4
  DECLARE @Lookup FLOAT
 	 if LOWER(@Method) = 'd2'
 	  	 Select @Lookup = Case @SubGroupSize
 	  	  	 When 1 Then 1.128
 	  	  	 When 2 Then 1.128
 	  	  	 When 3 Then 1.693
 	  	  	 When 4 Then 2.059
 	  	  	 When 5 Then 2.326 
 	  	  	 When 6 Then 2.534
 	  	  	 When 7 Then 2.704
 	  	  	 When 8 Then 2.847
 	  	  	 When 9 Then 2.970
 	  	  	 When 10 Then 3.087
 	  	  	 When 11 Then 3.173
 	  	  	 When 12 Then 3.258
 	  	  	 When 13 Then 3.336
 	  	  	 When 14 Then 3.407
 	  	  	 When 15 Then 3.472 
 	  	  	 When 16 Then 3.532
 	  	  	 When 17 Then 3.588
 	  	  	 When 18 Then 3.640
 	  	  	 When 19 Then 3.689
 	  	  	 When 20 Then 3.735
 	  	  	 When 21 Then 3.778
 	  	  	 When 22 Then 3.819
 	  	  	 When 23 Then 3.858
 	  	  	 When 24 Then 3.895
 	  	  	 When 25 Then 3.931 
 	  	  	 Else NULL
 	  	 End
 	 if LOWER(@Method) = 'd3'
 	  	 Select @Lookup = Case @SubGroupSize
 	  	  	 When 1 Then 0.853
 	  	  	 When 2 Then 0.853
 	  	  	 When 3 Then 0.888
 	  	  	 When 4 Then 0.880
 	  	  	 When 5 Then 0.864 
 	  	  	 When 6 Then 0.848
 	  	  	 When 7 Then 0.833
 	  	  	 When 8 Then 0.820
 	  	  	 When 9 Then 0.808
 	  	  	 When 10 Then 0.797
 	  	  	 When 11 Then 0.787
 	  	  	 When 12 Then 0.778
 	  	  	 When 13 Then 0.770
 	  	  	 When 14 Then 0.763
 	  	  	 When 15 Then 0.756 
 	  	  	 When 16 Then 0.750
 	  	  	 When 17 Then 0.744
 	  	  	 When 18 Then 0.739
 	  	  	 When 19 Then 0.734
 	  	  	 When 20 Then 0.729
 	  	  	 When 21 Then 0.724
 	  	  	 When 22 Then 0.720
 	  	  	 When 23 Then 0.716
 	  	  	 When 24 Then 0.712
 	  	  	 When 25 Then 0.708 
 	  	  	 Else NULL
 	  	 End
 	 If LOWER(@Method) = 'C4'
 	  	 Select @Lookup = Case @SubGroupSize
 	  	  	 -- Begin C4 Values
 	  	  	 When 1 Then 0.0000
 	  	  	 When 2 Then 0.7979
 	  	  	 When 3 Then 0.8862
 	  	  	 When 4 Then 0.9213
 	  	  	 When 5 Then 0.9400
 	  	  	 When 6 Then 0.9515
 	  	  	 When 7 Then 0.9594
 	  	  	 When 8 Then 0.9650
 	  	  	 When 9 Then 0.9693
 	  	  	 When 10 Then 0.9727
 	  	  	 When 11 Then 0.9754
 	  	  	 When 12 Then 0.9776
 	  	  	 When 13 Then 0.9794
 	  	  	 When 14 Then 0.9810
 	  	  	 When 15 Then 0.9823
 	  	  	 When 16 Then 0.9835
 	  	  	 When 17 Then 0.9845
 	  	  	 When 18 Then 0.9854
 	  	  	 When 19 Then 0.9862
 	  	  	 When 20 Then 0.9869
 	  	  	 When 21 Then 0.9876
 	  	  	 When 22 Then 0.9882
 	  	  	 When 23 Then 0.9887
 	  	  	 When 24 Then 0.9892
 	  	  	 When 25 Then 0.9896
 	  	  	 -- when greater than 25 use formula 	  	 
 	  	  	 Else  4.0 * ((@SubGroupSize - 1) / ((4.0 * @SubGroupSize) - 3)) 	  	 
 	  	 End
 	  	 --Select @Lookup = .991453
  RETURN @Lookup
END
