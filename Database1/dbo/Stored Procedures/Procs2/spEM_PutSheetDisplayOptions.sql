CREATE PROCEDURE dbo.spEM_PutSheetDisplayOptions
 	 @SheetId  	 Int,
 	 @OptionId 	 Int,
 	 @Value 	  	 VarChar(7000),
 	 @User_Id 	 Int
AS
  DECLARE @Insert_Id integer, 
 	   @PUId integer,
          @SheetIdToProcess integer
 	 DECLARE @ECId Int,@Isactive tinyint 	  	  	  	  	  	  	    
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSheetDisplayOptions',
                Convert(nVarChar(10),@SheetId) + ','  + 
 	  	 Convert(nVarChar(10),@OptionId) + ','  + 
 	  	 substring(Rtrim(Ltrim(@Value)),1,200) 	 + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the production line's security group.
  --
If ltrim(rtrim(@value)) = '' or ltrim(rtrim(@value)) is null
  Delete From Sheet_Display_Options where Sheet_Id = @SheetId and Display_Option_Id = @OptionId
else
  Begin
    Update Sheet_Display_Options set value = @Value Where Sheet_Id = @SheetId and Display_Option_Id = @OptionId
    If @@Rowcount = 0
      Insert Into Sheet_Display_Options (Sheet_Id,Display_Option_Id,Value) Values (@SheetId,@OptionId,@Value)
  End
  -- reset variablescrolling to scroll 
  IF @OptionId = 461 and @value = 1
  BEGIN
 Update Sheet_Display_Options set value = 1 Where Sheet_Id = @SheetId and Display_Option_Id = 449
   -- If @@Rowcount = 0
    --  Insert Into Sheet_Display_Options (Sheet_Id,Display_Option_Id,Value) Values (@SheetId,@OptionId,@Value)
  End
  --Sync up Display Option 193 between all Production Event display types for this particular Master Unit
  --ECR #32204
  If @OptionId = 193
    Begin
      Select @PUId = Master_Unit from Sheets where Sheet_Id = @SheetId
      Declare SheetsCursor Cursor For
        Select Sheet_Id from Sheets where Master_Unit = @PUId and Sheet_Type = 2
      Open SheetsCursor 
      While (0=0) Begin
        Fetch Next
          From SheetsCursor
          Into @SheetIdToProcess
          If (@@Fetch_Status <> 0) Break
          Update Sheet_Display_Options set value = @Value 
 	       Where Display_Option_Id = @OptionId and Sheet_Id = @SheetIdToProcess
          If @@Rowcount = 0
            Insert Into Sheet_Display_Options (Sheet_Id,Display_Option_Id,Value) Values (@SheetIdToProcess,@OptionId,@Value)
      End
      Close SheetsCursor
      Deallocate SheetsCursor
    End
 	 If @OptionId = 444 -- Activities - need to set title order
 	 Begin
 	  	 UPDATE Sheet_Variables SET Title_Var_Order_Id = 
 	  	  	 (SELECT Coalesce(MAX(a.Var_Order),0) 
 	  	  	  	 FROM Sheet_Variables a
 	  	  	  	 WHERE Sheet_Id = @SheetId and Title is Not Null and  a.Var_Order < Sheet_Variables.Var_Order)
 	  	 WHERE Sheet_Id = @SheetId and Title Is Null
 	 End
 	  	 IF @OptionId = 460 
 	 BEGIN
 	  	 SELECT @ECId = ec_id,@IsActive = Is_Active FROM Event_Configuration WHERE ED_Model_Id = 49300
 	  	 IF @value is not null AND @Value > 0    -- System Complete duration
 	  	  	 BEGIN
 	  	  	  	 IF @ECId Is Null OR @IsActive = 0
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 --call the sproc to insert the event spEM_SystemCompleteActivityAddModel
 	  	  	  	  	  	 EXECUTE dbo.spEM_SystemCompleteActivityAddModel 1
 	  	  	  	  	 END
 	  	  	 END
 	  	 ELSE IF @Value = 0 OR @Value IS NULL AND @ECId IS NOT NULL
 	  	  	 BEGIN
 	  	  	  	 --check all the values for this display option and deactivate if all are 0 or null
 	  	  	  	 IF (Select count(0) from Sheet_Display_Options where Display_Option_Id = 460 and value > 0) < 1 AND 
 	  	  	  	 (Select count(0) from dbo.Sheet_Variables where AutoComplete_Duration > 0) < 1 
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 EXECUTE dbo.spEM_SystemCompleteActivityAddModel 0
 	  	  	  	  	 END
 	  	  	 END
 	 END
 	  	  	 
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
