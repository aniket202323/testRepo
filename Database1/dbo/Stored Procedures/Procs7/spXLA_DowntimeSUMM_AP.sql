CREATE PROCEDURE dbo.spXLA_DowntimeSUMM_AP
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Pu_Id 	  	 Int 	  	 --Add-In's "Line" Is masterUnit here
 	 , @SelectSource  	 Int 	  	 --Slave Units Pu_Id in Timed_Event_
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @ReasonLevel 	  	 Int
 	 , @Crew_Desc 	  	 Varchar(10)
 	 , @Shift_Desc 	  	 Varchar(10)
 	 , @Prod_Id 	  	 Int
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 --1=Yes filter by Applied Product; 0 = No, Filter By Original Product
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
--SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
-- convert of these are done in spXLA_DowntimeSUMM_AP_NPT
EXECUTE dbo.spXLA_DowntimeSUMM_AP_NPT 	   @Start_Time, @End_Time, @Pu_Id, @SelectSource, @SelectR1 	  	 
 	 , @SelectR2, @SelectR3, @SelectR4, @SelectA1, @SelectA2 	  	 
 	 , @SelectA3, @SelectA4, @ReasonLevel, @Crew_Desc, @Shift_Desc 	  	 
 	 , @Prod_Id, @Group_Id, @Prop_Id 	 , @Char_Id, @IsAppliedProdFilter 	  	 
 	 , @Username, @Langid, 0,@InTimeZone
