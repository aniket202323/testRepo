CREATE Procedure dbo.spEMUP_PutUnitLocations
@Location_Id int,
@PU_Id int,
@Location_Code nvarchar(50),
@Location_Desc nvarchar(50),
@Prod_Id int,
@Maximum_Items int,
@Maximum_Dimension_X real,
@Maximum_Dimension_Y real,
@Maximum_Dimension_Z real,
@Maximum_Dimension_A real,
@Maximum_Alarm_Enabled bit,
@Minimum_Items int,
@Minimum_Dimension_X real,
@Minimum_Dimension_Y real,
@Minimum_Dimension_Z real,
@Minimum_Dimension_A real,
@Minimum_Alarm_Enabled bit,
@User_Id int,
@NewLocation_Id int OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMUP_PutUnitLocations',
             Convert(nVarChar(10),@Location_Id) + ','  + 
             Convert(nVarChar(10),@PU_Id) + ','  + 
             @Location_Code + ','  + 
             @Location_Desc + ','  + 
             Convert(nVarChar(10),@Prod_Id) + ','  + 
             Convert(nVarChar(10),@Maximum_Items) + ','  + 
             Convert(nVarChar(10),@Maximum_Dimension_X) + ','  + 
             Convert(nVarChar(10),@Maximum_Dimension_Y) + ','  + 
             Convert(nVarChar(10),@Maximum_Dimension_Z) + ','  + 
             Convert(nVarChar(10),@Maximum_Dimension_A) + ','  + 
             Convert(nVarChar(10),@Maximum_Alarm_Enabled) + ','  + 
             Convert(nVarChar(10),@Minimum_Items) + ','  + 
             Convert(nVarChar(10),@Minimum_Dimension_X) + ','  + 
             Convert(nVarChar(10),@Minimum_Dimension_Y) + ','  + 
             Convert(nVarChar(10),@Minimum_Dimension_Z) + ','  + 
             Convert(nVarChar(10),@Minimum_Dimension_A) + ','  + 
             Convert(nVarChar(10),@Minimum_Alarm_Enabled) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Location_Id is NULL
  Begin
    Insert Into Unit_Locations
      (PU_Id, Location_Code, Location_Desc, Prod_Id, Maximum_Items, Maximum_Dimension_X, 
      Maximum_Dimension_Y, Maximum_Dimension_Z, Maximum_Dimension_A, Maximum_Alarm_Enabled, Minimum_Items, 
      Minimum_Dimension_X, Minimum_Dimension_Y, Minimum_Dimension_Z, Minimum_Dimension_A, Minimum_Alarm_Enabled)
        Values
          (@PU_Id, @Location_Code, @Location_Desc, @Prod_Id, @Maximum_Items, @Maximum_Dimension_X, 
          @Maximum_Dimension_Y, @Maximum_Dimension_Z, @Maximum_Dimension_A, @Maximum_Alarm_Enabled, @Minimum_Items, 
          @Minimum_Dimension_X, @Minimum_Dimension_Y, @Minimum_Dimension_Z, @Minimum_Dimension_A, @Minimum_Alarm_Enabled)
    Select @NewLocation_Id = Scope_Identity()
  End
Else If @Location_Id is NOT NULL and @PU_Id is NOT NULL
  Begin
    Update Unit_Locations
      Set PU_Id = @PU_Id, Location_Code = @Location_Code, Location_Desc = @Location_Desc, Prod_Id = @Prod_Id, Maximum_Items = @Maximum_Items, 
          Maximum_Dimension_X = @Maximum_Dimension_X, Maximum_Dimension_Y = @Maximum_Dimension_Y, Maximum_Dimension_Z = @Maximum_Dimension_Z, 
          Maximum_Dimension_A = @Maximum_Dimension_A, Maximum_Alarm_Enabled = @Maximum_Alarm_Enabled, Minimum_Items = @Minimum_Items, 
          Minimum_Dimension_X = @Minimum_Dimension_X, Minimum_Dimension_Y = @Minimum_Dimension_Y, Minimum_Dimension_Z = @Minimum_Dimension_Z, 
          Minimum_Dimension_A = @Minimum_Dimension_A, Minimum_Alarm_Enabled = @Minimum_Alarm_Enabled
      Where Location_Id = @Location_Id
    Select @NewLocation_Id = @Location_Id
  End
Else If @Location_Id is NOT NULL and @PU_Id is NULL
  Begin
    Declare @Comment_Id int
    Select @Comment_Id = Comment_Id From Unit_Locations Where Location_Id = @Location_Id
    If @Comment_Id is not null
      Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 Where Comment_Id = @Comment_Id
    Delete From Unit_Locations
      Where Location_Id = @Location_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
