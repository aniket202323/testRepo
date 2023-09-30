CREATE FUNCTION dbo.fnEM_ConvertTableFieldValue(@CurrentValue nvarchar(2000),@DataTypeId Int,@ColumnNumber Int) 
 	 Returns 	  nvarchar(2000) 
BEGIN
 	 DECLARE @Value1 nvarchar(2000)
 	 DECLARE @Value2 nvarchar(2000)
 	 DECLARE @Value3 nvarchar(2000)
 	 DECLARE @ReturnVal nvarchar(2000)
-- 	 IF @DataTypeId IN (1,2,11,12,22,51)
 	 SET @Value1 = @CurrentValue
 	 IF @DataTypeId = 9 -- Unit Id
 	  	 SELECT @Value1 = b.PL_Desc,@Value2 = a.PU_Desc
 	  	 FROM Prod_Units a 
 	  	 JOIN Prod_Lines b On b.PL_Id = a.PL_Id
 	  	 WHERE a.PU_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 10 -- Variable Id
 	  	 SELECT @Value1 = c.PL_Desc,@Value2 = b.PU_Desc,@Value3 =a.Var_Desc
 	  	 FROM Variables a 
 	  	 JOIN Prod_Units b On b.PU_Id = a.PU_Id
 	  	 JOIN Prod_Lines c On c.PL_Id = b.PL_Id
 	  	 WHERE  a.Var_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 16 -- Production Status
 	  	 SELECT @Value1 = a.ProdStatus_Desc
 	  	 FROM Production_Status a
 	  	 WHERE a.ProdStatus_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 23 --Characteristic
 	  	 SELECT @Value1 = b.Prop_Desc,@Value2 = a.Char_Desc
 	  	 FROM Characteristics a
 	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	 WHERE a.Char_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 24 --Color Scheme
 	  	 SELECT @Value1 = a.CS_Desc
 	  	 FROM Color_Scheme a
 	  	 WHERE a.CS_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 27 --Event Type
 	  	 SELECT @Value1 = a.ET_Desc
 	  	 FROM Event_Types a
 	  	 WHERE a.ET_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 30 --Access Level
 	  	 SELECT @Value1 =  a.AL_Desc
 	  	 FROM Access_Level a
 	  	 WHERE a.AL_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 34 --Colors
 	  	 SELECT @Value1 =  a.Color_Desc
 	  	 FROM Colors a
 	  	 WHERE a.Color_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 35 -- Customer
 	  	 SELECT @Value1 =  a.Customer_Code
 	  	 FROM Customer a
 	  	 WHERE a.Customer_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 36 --Products
 	  	 SELECT @Value1 =  a.Prod_Code
 	  	 FROM Products a
 	  	 WHERE a.Prod_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 37 --Product Group
 	  	 SELECT @Value1 =  a.Product_Grp_Desc
 	  	 FROM Product_Groups a
 	  	 WHERE a.Product_Grp_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 39 --Reason Tree
 	  	 SELECT @Value1 =  a.Tree_Name
 	  	 FROM Event_Reason_Tree a
 	  	 WHERE a.Tree_Name_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 40 --Reasons
 	  	 SELECT @Value1 =  a.Event_Reason_Name
 	  	 FROM Event_Reasons a
 	  	 WHERE a.Event_Reason_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 59 --Production Plan Path
 	  	 SELECT @Value1 =  a.Path_Code
 	  	 FROM PrdExec_Paths a
 	  	 WHERE a.Path_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 61 --Product Family
 	  	 SELECT @Value1 =  a.Product_Family_Desc
 	  	 FROM Product_Family a
 	  	 WHERE a.Product_Family_Id = Convert(int,@CurrentValue)
 	 IF @DataTypeId = 63 --Data Source
 	  	 SELECT @Value1 = a.DS_Desc
 	  	 FROM Data_Source a 
 	  	 WHERE a.DS_Id = Convert(int,@CurrentValue)
 	 IF @ColumnNumber = 1
 	  	 SET @ReturnVal = @Value1
 	 IF @ColumnNumber = 2
 	  	 SET @ReturnVal = @Value2
 	 IF @ColumnNumber = 3
 	  	 SET @ReturnVal = @Value3
 	 RETURN (@ReturnVal)
END
