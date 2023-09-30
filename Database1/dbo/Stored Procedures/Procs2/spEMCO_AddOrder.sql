Create Procedure dbo.spEMCO_AddOrder
@Customer_Id int,
@Customer_Order_Number nvarchar (50),
@Plant_Order_Number nvarchar(50),
@Corporate_Order_Number nvarchar(50),
@Schedule_Block_Number nvarchar(50),
@Order_Type nVarChar(10),
@Order_Status nVarChar(10),
@Entered_Date datetime,
@Entered_By int,
@Forecast_Mfg_Date datetime,
@Forecast_Ship_Date datetime,
@Actual_Mfg_Date datetime,
@Actual_Ship_Date datetime,
@Total_Line_Items int,
@Order_Instructions nvarchar(255),
@Order_General_1 nVarChar(25),
@Order_General_2 nVarChar(25),
@Order_General_3 nVarChar(25),
@Order_General_4 nVarChar(25),
@Order_General_5 nVarChar(25),
@Consignee_Id int,
@User_Id int,
@Order_Id int OUTPUT
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMCO_AddOrder',
                convert(nVarChar(10),  @Customer_Id) +  "," + @Customer_Order_Number +  "," + @Plant_Order_Number +  "," + @Corporate_Order_Number +  "," + @Schedule_Block_Number +  "," + 
 	    @Order_Type +  "," + @Order_Status +  "," + convert(nVarChar(25), @Entered_Date) +  "," + convert(nVarChar(10), @Entered_By) +  "," + convert(nVarChar(25), @Forecast_Mfg_Date) +  "," + convert(nVarChar(25), @Forecast_Ship_Date) + "," + 
 	   convert(nVarChar(25), @Actual_Mfg_Date) +  "," + convert(nVarChar(25), @Actual_Ship_Date) +  "," + convert(nVarChar(10), @Total_Line_Items) +  "," + @Order_Instructions +  "," + @Order_General_1 +  "," + @Order_General_2 +  "," + @Order_General_3 + "," + 
  	   @Order_General_4 +  "," + @Order_General_5 +  "," + convert(nVarChar(10), @Consignee_Id) + "," + 
 	    Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
insert into Customer_Orders (Customer_Id,
Customer_Order_Number,
Plant_Order_Number,
Corporate_Order_Number,
Schedule_Block_Number,
Order_Type,
Order_Status,
Entered_Date,
Entered_By,
Forecast_Mfg_Date,
Forecast_Ship_Date,
Actual_Mfg_Date,
Actual_Ship_Date,
Total_Line_Items,
Order_Instructions,
Order_General_1,
Order_General_2,
Order_General_3,
Order_General_4,
Order_General_5,
Consignee_Id)
values 	 (@Customer_Id,
 	  	  	  	  	 @Customer_Order_Number,
 	  	  	  	  	 @Plant_Order_Number,
 	  	  	  	  	 @Corporate_Order_Number,
 	  	  	  	  	 @Schedule_Block_Number,
 	  	  	  	  	 @Order_Type,
 	  	  	  	  	 @Order_Status,
 	  	  	  	  	 @Entered_Date,
 	  	  	  	  	 @Entered_By,
 	  	  	  	  	 @Forecast_Mfg_Date,
 	  	  	  	  	 @Forecast_Ship_Date,
 	  	  	  	  	 @Actual_Mfg_Date,
 	  	  	  	  	 @Actual_Ship_Date,
 	  	  	  	  	 @Total_Line_Items,
 	  	  	  	  	 @Order_Instructions,
 	  	  	  	  	 @Order_General_1,
 	  	  	  	  	 @Order_General_2,
 	  	  	  	  	 @Order_General_3,
 	  	  	  	  	 @Order_General_4,
 	  	  	  	  	 @Order_General_5,
 	  	  	  	  	 @Consignee_Id)
select @Order_Id = Scope_Identity()
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
