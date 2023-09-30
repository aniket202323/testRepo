CREATE PROCEDURE dbo.spEMCC_SaveInput
  @CalcID int,
  @IAlias nvarchar(50),
  @IName nvarchar(50),
  @Order int,
  @EntityId int,
  @AttributeId int,
  @DefaultVal nvarchar(255),
  @Optional bit, 
  @NonTrigger bit, 
  @User_Id int,
  @Input_Id int = 0 Output 
AS
  DECLARE @Insert_Id integer 
  Declare @ResultVarId Integer, @OldDefaultVal nVarChar(25), @OldInputEntityId Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, substring('spEMCC_CalcConfig_InputSave', 1, 30),
           substring(
                substring(Convert(nvarchar(20),@Input_Id),1,15) + ','  + 
                substring(Convert(nvarchar(20),@CalcID),1,55) + ','  + 
                substring(Convert(nVarChar(25),ltrim(rtrim(@IAlias))),1,25) + ','  + 
                substring(Convert(nVarChar(25),ltrim(rtrim(@IName))),1,25) + ','  + 
                substring(Convert(nVarChar(10),@Order),1,15) + ','  + 
                substring(Convert(nvarchar(20),@EntityId),1,15) + ','  + 
                substring(Convert(nvarchar(20),@AttributeId),1,15) + ','  + 
                substring(Convert(nVarChar(10),ltrim(rtrim(@DefaultVal))),1,25) + ','  + 
                substring(Convert(nVarChar(2),@Optional),1,1) + ','  + 
                substring(Convert(nVarChar(2),@NonTrigger),1,1) + ','  + 
 	    substring(Convert(nvarchar(20),@User_Id),1,10),
            1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
Select @Input_Id = isnull(@Input_Id,0)
if @DefaultVal = ''
  select @DefaultVal = '0'
if @Input_Id > 0
  begin
    Select @OldDefaultVal = Null
    Select @OldDefaultVal = default_value, @OldInputEntityId = calc_input_entity_id
 	 From calculation_inputs
    Where calc_input_id = @Input_Id
    update calculation_inputs
      set calculation_id = @CalcID, alias = @IAlias, input_name = @IName, calc_input_order = @Order, 
            calc_input_entity_id = @EntityId, calc_input_attribute_id = @AttributeId, default_value = @DefaultVal, 
 	  	  	 optional = @Optional,Non_Triggering = @NonTrigger
      where calc_input_id = @Input_Id
      If @EntityId <> 1
        Update calculation_input_Data Set Default_Value =  @DefaultVal
 	   Where calc_input_id = @Input_Id
      Else If @OldDefaultVal is not null and @DefaultVal is not null
             Update calculation_input_Data Set Default_Value =  @DefaultVal
 	       Where calc_input_id = @Input_Id And ((Default_Value = @OldDefaultVal) or (Default_Value is null))
--Remove the input data if the EntityId changes
    If @OldInputEntityId <> @EntityId
      Begin
        Delete from calculation_input_data where calc_input_id = @Input_Id
      End
  end
else
  begin
    insert into calculation_inputs
      (calculation_id, alias, input_name, calc_input_order, calc_input_entity_id, calc_input_attribute_id, default_value, optional,Non_Triggering)
      values(@CalcID, @IAlias, @IName, @Order, @EntityId, @AttributeId, @DefaultVal, @Optional,@NonTrigger
)
    Select @Input_Id = Scope_Identity()
    If @EntityId = 1
     Begin
       Select  @ResultVarId = Null
       Select @ResultVarId = Var_ID From Variables Where calculation_id = @CalcID
       If (@ResultVarId is not null) and  (@ResultVarId <> 0)
         Insert Into  calculation_input_Data (Calc_Input_Id,Member_Var_Id,Result_Var_Id,Input_Name,Default_Value)
 	   Values(@Input_Id,Null,@ResultVarId,Null,@DefaultVal) 
     End
  end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
  WHERE Audit_Trail_Id = @Insert_Id
