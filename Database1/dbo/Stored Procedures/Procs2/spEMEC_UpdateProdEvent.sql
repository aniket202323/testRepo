Create Procedure dbo.spEMEC_UpdateProdEvent
@Event_Subtype_Id int = NULL,
@Event_Subtype_Desc nvarchar(50),
@Event_Mask nvarchar(30),
@Dimension_A_Enabled bit,
@Dimension_A_Name nvarchar(50),
@Dimension_A_Eng_Units Int,
@Dimension_X_Name nvarchar(50),
@Dimension_X_Eng_Units Int,
@Dimension_Y_Enabled bit,
@Dimension_Y_Name nvarchar(50),
@Dimension_Y_Eng_Units Int,
@Dimension_Z_Enabled bit,
@Dimension_Z_Name nvarchar(50),
@Dimension_Z_Eng_Units Int,
@User_Id int,
@New_Id int OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateProdEvent',
      IsNull(Convert(nVarChar(10),@Event_Subtype_Id),'Null') + ','  + 
 	  IsNull(@Event_Subtype_Desc,'Null') + ',' +
 	  IsNull(@Event_Mask,'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_A_Enabled),'Null') + ','  + 
 	  IsNull(@Dimension_A_Name,'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_A_Eng_Units),'Null') + ',' +
 	  IsNull(@Dimension_X_Name,'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_X_Eng_Units),'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_Y_Enabled),'Null') + ','  + 
 	  IsNull(@Dimension_Y_Name,'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_Y_Eng_Units),'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_Z_Enabled),'Null') + ','  + 
 	  IsNull(@Dimension_Z_Name,'Null') + ',' +
 	  IsNull(Convert(nVarChar(10),@Dimension_Z_Eng_Units),'Null') + ',' +
      IsNull(Convert(nVarChar(10),@User_Id),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
select @New_Id = @Event_Subtype_Id
if @Event_Subtype_Id is NULL
  Begin
    insert into event_subtypes (event_subtype_desc, et_id, event_mask, dimension_a_enabled, dimension_a_name, Dimension_A_Eng_Unit_Id,
      dimension_x_name, Dimension_X_Eng_Unit_Id, dimension_y_enabled, dimension_y_name, Dimension_Y_Eng_Unit_Id, dimension_z_enabled,
      dimension_z_name, Dimension_Z_Eng_Unit_Id) values (@Event_Subtype_Desc, 1, @Event_Mask, @Dimension_A_Enabled, @Dimension_A_Name,
     @Dimension_A_Eng_Units, @Dimension_X_Name, @Dimension_X_Eng_Units, @Dimension_Y_Enabled, @Dimension_Y_Name, 
     @Dimension_Y_Eng_Units, @Dimension_Z_Enabled, @Dimension_Z_Name, @Dimension_Z_Eng_Units)
    select @New_Id = Scope_Identity()
  End
else
  Begin
    update event_subtypes set event_subtype_desc = @Event_Subtype_Desc, event_mask = @Event_Mask,
      dimension_a_enabled = @Dimension_A_Enabled, dimension_a_name = @Dimension_A_Name, Dimension_A_Eng_Unit_Id = @Dimension_A_Eng_Units, 
      dimension_x_name = @Dimension_X_Name, Dimension_X_Eng_Unit_Id = @Dimension_X_Eng_Units, dimension_y_enabled = @Dimension_Y_Enabled,
      dimension_y_name = @Dimension_Y_Name, Dimension_Y_Eng_Unit_Id = @Dimension_Y_Eng_Units, dimension_z_enabled = @Dimension_Z_Enabled,
      dimension_z_name = @Dimension_Z_Name, Dimension_Z_Eng_Unit_Id = @Dimension_Z_Eng_Units
    where event_subtype_id = @Event_Subtype_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
/*
if @Event_Subtype_Id is NULL
  Begin
    insert into event_subtypes (event_subtype_desc, et_id) values (@Event_Subtype_Desc, 1)
    select @Event_Subtype_Id = event_subtype_id from event_subtypes where event_subtype_desc = @Event_Subtype_Desc and et_id = 1
  End
update event_subtypes set event_subtype_desc = @Event_Subtype_Desc, event_mask = @Event_Mask,
  dimension_a_enabled = @Dimension_A_Enabled, dimension_a_name = @Dimension_A_Name, dimension_a_eng_units = @Dimension_A_Eng_Units, 
  dimension_x_name = @Dimension_X_Name, dimension_x_eng_units = @Dimension_X_Eng_Units, dimension_y_enabled = @Dimension_Y_Enabled,
  dimension_y_name = @Dimension_Y_Name, dimension_y_eng_units = @Dimension_Y_Eng_Units, dimension_z_enabled = @Dimension_Z_Enabled,
  dimension_z_name = @Dimension_Z_Name, dimension_z_eng_units = @Dimension_Z_Eng_Units
where event_subtype_id = @Event_Subtype_Id
*/
