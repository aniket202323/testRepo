CREATE FUNCTION dbo.fnCMN_OEERates(@Run_Minutes FLOAT, @Loading_Minutes FLOAT, @Performance_Minutes FLOAT, @Good_Production FLOAT, @Ideal_Production FLOAT, @Waste FLOAT) 
     RETURNS @OEERates Table (Available_Rate FLOAT, Performance_Rate FLOAT, Quality_Rate FLOAT, OEE FLOAT, Actual_Rate FLOAT, Ideal_Rate FLOAT, Actual_Yield FLOAT, Good_Yield FLOAT)
AS 
Begin
-------------------------
-- Local Variables
-------------------------
 	 Declare @Available_Rate FLOAT
 	 Declare @Performance_Rate FLOAT
 	 Declare @Quality_Rate FLOAT
 	 Declare @OEE FLOAT
 	 Declare @Ideal_Rate FLOAT
 	 Declare @Actual_Rate FLOAT
 	 Declare @Actual_Yield FLOAT
 	 Declare @Good_Yield FLOAT
 	 
 	 Declare @Total_Production FLOAT
 	 Declare @OEERateCap bit
 	 select @OEERateCap = dbo.fnCMN_OEERateIsCapped()
 	 Select @Total_Production = @Good_Production + @Waste
     Select @Ideal_Rate = Case When @Run_Minutes=0 Then 0.0 Else @Ideal_Production / @Run_Minutes End
     if @Run_Minutes - @Performance_Minutes <= 0
 	  	 Select @Actual_Rate = 0.0
 	 Else
 	      Select @Actual_Rate = Case When @Run_Minutes=0 Then 0.0 Else (@Total_Production) / (@Run_Minutes) End
     -- Operating Time /  Planned Production Time
     Select @Available_Rate = Case When @Loading_Minutes=0 Then 0.0 Else @Run_Minutes / @Loading_Minutes End 
     -- Good Pieces / Total Pieces
     Select @Quality_Rate = Case When @Total_Production=0 Then 0.0 Else @Good_Production / (@Total_Production) End 
     -- (TotalPieces / RunTime) / IdealRate
     Select @Performance_Rate = Case When @Ideal_Rate=0 or @Run_Minutes=0 Then 0.0 Else ((@Total_Production) / @Run_Minutes) / @Ideal_Rate End 
 	 ------------------------------------------
 	 -- 0 means that OEE should not exceed 100%
 	 -- 1 means YES Cap OEE at 100%
 	 ------------------------------------------
 	 If @OEERateCap = 1
 	  	 If (@Performance_Rate) > 1.0 
 	  	  	 Select @Performance_Rate = 1.0
 	  Select @Actual_Yield = 0
 	  Select @Good_Yield =   0
 	  If @Ideal_Production > 0 
 	  Begin
 	  	  Select @Actual_Yield =  @Total_Production / @Ideal_Production
 	  	  Select @Good_Yield =    @Good_Production  / @Ideal_Production
 	  End
     -- Calculate OEE
     Select @OEE = (@Available_Rate * @Quality_Rate * @Performance_Rate)
     -- Return
     insert Into @OEERates(Available_Rate, Performance_Rate, Quality_Rate, OEE, Actual_Rate, Ideal_Rate, Actual_Yield, Good_Yield)
     Values(@Available_Rate * 100, @Performance_Rate * 100, @Quality_Rate * 100, @OEE * 100, @Actual_Rate, @Ideal_Rate, @Actual_Yield * 100, @Good_Yield * 100)
--select * from @OEERates
--/******
     RETURN
END
--*******/
