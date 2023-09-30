Create Procedure dbo.spRS_COAGetTriggerType
@WRD_Id int,
@Update tinyint,
@User_Id int,
@WRT_Id int OUTPUT,
@RRD_Id int OUTPUT,
@WAC_Id int OUTPUT,
@WAC_Desc varchar(50) OUTPUT,
@WRDC_Id int OUTPUT,
@Comparison_Operator_Id tinyint OUTPUT,
@Comparison_Operator_Value varchar(50) OUTPUT,
@Value_Id int OUTPUT,
@Value_Desc varchar(50) OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetTriggerType',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@Update) + ','  + 
             Convert(varchar(10),@User_Id) + ','  + 
             Convert(varchar(10),@WRT_Id) + ','  + 
             Convert(varchar(10),@RRD_Id) + ','  + 
             Convert(varchar(10),@WAC_Id) + ','  + 
             @WAC_Desc + ','  + 
             Convert(varchar(10),@WRDC_Id) + ','  + 
             Convert(varchar(10),@Comparison_Operator_Id) + ','  + 
             @Comparison_Operator_Value + ','  + 
             Convert(varchar(10),@Value_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
If @Update = 1 	 --Get Data
  Begin
    Select @RRD_Id = d.RRD_Id, @WRT_Id = WRT_Id, @WAC_Id = c.WAC_Id, @WAC_Desc = c.WAC_Desc, 
    @WRDC_Id = r.WRDC_Id, @Comparison_Operator_Id = o.Comparison_Operator_Id, 
    @Comparison_Operator_Value = o.Comparison_Operator_Value, @Value_Id = r.Value
    From Web_Report_Definitions d
    Left Outer Join Web_Report_Definition_Criteria r on r.WRD_Id = d.WRD_Id
    Left Outer Join Web_App_Criteria c on c.WAC_Id = r.WAC_Id
    Left Outer Join Comparison_Operators o on o.Comparison_Operator_Id = r.Comparison_Operator_Id
    Where d.WRD_Id = @WRD_Id
    If @WAC_Id = 1 or @WAC_Id = 2 or @WAC_Id = 3 or @WAC_Id = 6 or @WAC_Id = 7
      Select @Value_Desc = Customer_Name From Customer Where Customer_Id = @Value_Id
    Else If @WAC_Id = 4
      Select @Value_Desc = Prod_Desc From Products Where Prod_Id = @Value_Id
    Else If @WAC_Id = 5
      Select @Value_Desc = Product_Grp_Desc From Product_Groups Where Product_Grp_Id = @Value_Id
  End
Else If @Update = 2  --Update Time-Based Trigger Info
  Begin
    Update Web_Report_Definitions set RRD_Id = @RRD_Id, WRT_Id = @WRT_Id
    From Web_Report_Definitions
    Where WRD_Id = @WRD_Id    
  End
Else If @Update = 3 	 --Update Criteria Configuration
  Begin
    Update Web_Report_Definitions set RRD_Id = @RRD_Id, WRT_Id = @WRT_Id
    From Web_Report_Definitions
    Where WRD_Id = @WRD_Id    
    If (@WRDC_Id is NULL or @WRDC_Id = 0) and (@WRT_Id = 1 or @WRT_Id = 2 or @WRT_Id = 3)
      Begin
        if (@WRD_Id is Not NULL) and (@WAC_Id is Not NULL)
          Begin
            Insert into Web_Report_Definition_Criteria (WRD_Id, WAC_Id, Value, Comparison_Operator_Id) Values (@WRD_Id, @WAC_Id, @Value_Id, @Comparison_Operator_Id)
            select @WRDC_Id = Scope_Identity()
          End
      End
    Else If @WRDC_Id <> 0 and (@WRT_Id = 1 or @WRT_Id = 2)
      Begin
        Delete From Web_Report_Definition_Criteria Where WRDC_Id = @WRDC_Id
      End
    Else If @WRT_Id = 3
      Begin
        Delete From Web_Report_Definition_Criteria Where WRD_Id = @WRD_Id
      End
  End
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
