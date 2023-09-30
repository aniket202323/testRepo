Create Procedure dbo.spEMCO_EditLineItem
@Order_Line_Id int,
@Line_Item_Number int,
@Prod_Id int,
@Ordered_Quantity float,
@Ordered_UOM nVarChar(10),
@Dimension_X real,
@Dimension_Y real,
@Dimension_Z real,
@Dimension_A real,
@Complete_Date datetime,
@Order_Line_General_1 nvarchar(255),
@Order_Line_General_2 nvarchar(255),
@Order_Line_General_3 nvarchar(255),
@Order_Line_General_4 nvarchar(255),
@Order_Line_General_5 nvarchar(255),
@Consignee_Id int,
@User_Id int,
@TolA 	 Real = Null,
@TolX 	 Real = Null,
@TolY 	 Real = Null,
@TolZ 	 Real = Null,
@ShipTo 	 Int = Null
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEMCO_EditLineItem' ,
                convert(nVarChar(10), @Order_Line_Id ) +  "," + convert(nVarChar(10), @Line_Item_Number) +  "," + convert(nVarChar(10),  @Prod_Id) +  "," + convert(nVarChar(10), @Ordered_Quantity) +  "," + @Ordered_UOM + "," + 
 	    convert(nVarChar(10), @Dimension_X) +  "," + convert(nVarChar(10), @Dimension_Y) +  "," + convert(nVarChar(10), @Dimension_Z) +  "," + convert(nVarChar(10), @Dimension_A) +  "," + convert(nVarChar(25), @Complete_Date) + "," + 
 	     @Order_Line_General_1 +  "," + @Order_Line_General_2 +  "," + @Order_Line_General_3 +  "," + @Order_Line_General_4 +  "," + @Order_Line_General_5 +  "," + convert(nVarChar(10), @Consignee_Id) +  "," + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
update Customer_Order_Line_Items
set 	 Line_Item_Number = @Line_Item_Number,
 	 Prod_Id = @Prod_Id,
 	 Ordered_Quantity = @Ordered_Quantity,
 	 Ordered_UOM = @Ordered_UOM,
 	 Dimension_X = @Dimension_X,
 	 Dimension_Y = @Dimension_Y,
 	 Dimension_Z = @Dimension_Z,
 	 Dimension_A = @Dimension_A,
 	 Complete_Date = @Complete_Date,
 	 Order_Line_General_1 = @Order_Line_General_1,
 	 Order_Line_General_2 = @Order_Line_General_2,
 	 Order_Line_General_3 = @Order_Line_General_3,
 	 Order_Line_General_4 = @Order_Line_General_4,
 	 Order_Line_General_5 = @Order_Line_General_5,
 	 Consignee_Id = @Consignee_Id,
 	 Dimension_A_Tolerance = @TolA,
 	 Dimension_X_Tolerance = @TolX,
 	 Dimension_Y_Tolerance = @TolY,
 	 Dimension_Z_Tolerance = @TolZ,
 	 ShipTo_Id = @ShipTo
where Order_Line_Id = @Order_Line_Id
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
