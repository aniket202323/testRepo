Create Procedure dbo.spDS_GetPatterns
 @PPId int,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
IF @RegionalServer = 1
BEGIN
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @CHT(HeaderTag,Idx) Values (16384,1) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16356,2) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,3) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16543,4) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16544,5) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16545,6) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16546,7) -- 
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Tag] = PS.PP_Setup_Id, 
 	  	  	 [Pattern] = PS.Pattern_Code, 
 	  	  	 [Forecast Qty] = PS.Forecast_Quantity, 
 	  	  	 [Status] = PPS.PP_Status_Desc, 
 	  	  	 [Base Dimension X] = PS.Base_Dimension_X, 
 	  	  	 [Base Dimension Y] = PS.Base_Dimension_Y, 
 	  	  	 [Base Dimension Z] = PS.Base_Dimension_Z, 
 	  	  	 [Base Dimension A] = PS.Base_Dimension_A
 	 From Production_Setup PS
 	 Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PS.PP_Status_Id
 	 Where PS.PP_Id = @PPId
END
ELSE
BEGIN
 	 Select PS.PP_Setup_Id, PS.Pattern_Code as 'Pattern Code', PS.Forecast_Quantity as 'Forecast Quantity', PPS.PP_Status_Desc as 'Status', 
 	  	  PS.Base_Dimension_X as 'Base Dimension X', PS.Base_Dimension_Y as 'Base Dimension Y', PS.Base_Dimension_Z as 'Base Dimension Z', 
 	  	  PS.Base_Dimension_A as 'Base Dimension A'
 	 From Production_Setup PS
 	 Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PS.PP_Status_Id
 	 Where PS.PP_Id = @PPId
END
