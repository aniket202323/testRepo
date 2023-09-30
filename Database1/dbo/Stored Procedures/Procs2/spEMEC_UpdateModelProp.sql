Create Procedure dbo.spEMEC_UpdateModelProp
 	 @EC_Id  	  	  	 int,
 	 @ED_Field_Id  	 int,
 	 @Alias  	  	  	 nvarchar(50),
 	 @PU_Id  	  	  	 int,
 	 @Value  	  	  	 nvarchar(1000),
 	 @TableId  	  	 TinyInt,
 	 @User_Id  	  	 int
as
/* Unused parameters */
Declare @ED_Attribute_Id int,@ST_Id tinyint,@IsTrigger tinyint,@Sampling_Offset int
Select @ED_Attribute_Id = NULL,@ST_Id = NULL,@IsTrigger = NULL,@Sampling_Offset = NULL
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateModelProp',
        Coalesce(Convert(nVarChar(10),@EC_Id),'(null)') + ','  + 
 	 Coalesce(Convert(nVarChar(10),@ED_Field_Id),'(null)') + ','  + 
 	 Coalesce(@Alias,'(null)') + ','  + 
 	 Coalesce(Convert(nVarChar(10),@PU_Id),'(null)') + ','  + 
 	 Coalesce(@Value,'(null)') + ','  + 
 	 Coalesce(Convert(nVarChar(10),@TableId),'(null)') + ','  + 
    Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @Prefix nvarchar(20),@FieldType Int
Select @Prefix = COALESCE(t.Prefix,''),@FieldType = t.ED_Field_Type_Id
  From ED_FieldTypes t
  Join ED_Fields f on f.ED_Field_Type_Id = t.ED_Field_Type_Id and ED_Field_Id = @ED_Field_Id
If @FieldType in (61,63) and @Value = '0' --None
 	 Select @Value = Null
if @Prefix <> ''
  Select @Value = @Prefix + @Value
If @TableId = 2 /* new user_defined propertys */
  Begin
 	 Declare @Config_Prop_Id Int
 	 Select @Config_Prop_Id = EC_Id From Event_Configuration_Properties Where EC_Id = @EC_Id and ED_Field_Prop_Id = @ED_Field_Id
 	 If @Config_Prop_Id is null
 	  	 Insert into Event_Configuration_Properties(EC_Id,ED_Field_Prop_Id,Value) Values (@EC_Id,@ED_Field_Id,@Value)
 	 Else
 	  	 Update Event_Configuration_Properties Set Value = @Value Where EC_Id = @EC_Id and ED_Field_Prop_Id = @ED_Field_Id
  End
Else
 Begin
  if (select count(*) from event_configuration_data where ec_id = @EC_Id and ed_field_id = @ED_Field_Id) = 0
   Begin
    Declare @ECV_Id int
    insert into event_configuration_values(value) values (@Value) 
    select @ECV_Id = IDENT_CURRENT('event_configuration_values')
    insert into event_configuration_data (EC_Id, ED_Field_Id, ECV_Id, PU_Id, ED_Attribute_Id, ST_Id, IsTrigger, Sampling_Offset) 
    Values (@EC_Id, @ED_Field_Id,  @ECV_Id, @PU_Id, @ED_Attribute_Id, @ST_Id, @IsTrigger, @Sampling_Offset)
   End
  else
   Begin
    If @Alias IS NULL 
      BEGIN
        If @PU_Id IS NULL 
          BEGIN
            update event_configuration_values set event_configuration_values.value = @Value
              where ecv_id = (select ecv_id from event_configuration_data where ec_id = @EC_id and ed_field_id = @ED_Field_Id)
            update event_configuration_data set ed_attribute_id = @ED_Attribute_Id, st_id = @ST_Id, istrigger = @IsTrigger, sampling_offset = @Sampling_Offset
              where ec_id = @EC_id and ed_field_id = @ED_Field_Id
          END
        ELSE
          BEGIN
            update event_configuration_values set event_configuration_values.value = @Value
              where ecv_id = (select ecv_id from event_configuration_data where ec_id = @EC_id and ed_field_id = @ED_Field_Id and alias IS NULL and pu_id = @pu_ID)
            update event_configuration_data set ed_attribute_id = @ED_Attribute_Id, st_id = @ST_Id, istrigger = @IsTrigger, sampling_offset = @Sampling_Offset
              where ec_id = @EC_id and ed_field_id = @ED_Field_Id  and pu_id = @pu_ID
          END
      END
    ELSE
      BEGIN
        If @PU_Id IS NULL 
          BEGIN
            update event_configuration_values set event_configuration_values.value = @Value
              where ecv_id = (select ecv_id from event_configuration_data where ec_id = @EC_id and ed_field_id = @ED_Field_Id and alias = @Alias and pu_id IS NULL)
            update event_configuration_data set ed_attribute_id = @ED_Attribute_Id, st_id = @ST_Id, istrigger = @IsTrigger, sampling_offset = @Sampling_Offset
              where ec_id = @EC_id and ed_field_id = @ED_Field_Id and alias = @Alias
          END
        ELSE
          BEGIN
            update event_configuration_values set event_configuration_values.value = @Value
              where ecv_id = (select ecv_id from event_configuration_data where ec_id = @EC_id and ed_field_id = @ED_Field_Id and alias = @Alias and pu_id = @pu_ID)
            update event_configuration_data set ed_attribute_id = @ED_Attribute_Id, st_id = @ST_Id, istrigger = @IsTrigger, sampling_offset = @Sampling_Offset
              where ec_id = @EC_id and ed_field_id = @ED_Field_Id and alias = @Alias and pu_id = @pu_ID
          END
      END
   End
  End
----------------------------------------
-- If Model 5014 Autolog Waste Calc
-- is being used, this will update the
-- model configuration
----------------------------------------
Declare @Is_Active bit,@ModelId Int
Select @Is_Active = Isnull(Is_Calculation_Active,0), @ModelId = ED_Model_Id From Event_Configuration Where EC_Id = @EC_Id
If @Is_Active = 1 and @ModelId = 5400
 	 exec spEMEC_ConfigureModel5014 @EC_Id, 1
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
