Create Procedure dbo.spEMEC_UpdateWasteTypes
@WET_Id int = Null,
@WET_Name nVarChar(100),
@ReadOnly bit,
@User_Id int
AS
Declare @Insert_Id int,@Sql nvarchar(1000)
DECLARE @TestId INT
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateWasteTypes',Convert(nVarChar(10),@WET_Id) + ','  + 
             @WET_Name + ','  + Convert(nVarChar(10),@ReadOnly) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @WET_Id is Null
BEGIN
 	 SELECT @WET_Id = WET_Id FROM Waste_Event_Type WHERE WET_Name = @WET_Name
 	 IF @WET_Id IS NOT NULL
 	 BEGIN
 	  	 RETURN(-100)
 	 END
 	 If Exists (select * from dbo.syscolumns where name = 'WET_Name_Local' and id =  object_id(N'[Waste_Event_Type]'))
 	 BEGIN
 	  	 Select @Sql =  'INSERT INTO Waste_Event_Type(WET_Name_Local, ReadOnly)'
 	 END
 	 Else
 	 BEGIN
 	  	 Select @Sql =  'INSERT INTO Waste_Event_Type(WET_Name, ReadOnly)'
 	 END
 	 Select @Sql = @Sql + ' VALUES(''' + replace(@WET_Name,'''','''''') + ''','  + Convert(nVarChar(10),@ReadOnly) + ')'
 	 Execute(@Sql)
 	 Select @WET_Id = WET_Id From Waste_Event_Type Where WET_Name = @WET_Name
END
Else
BEGIN
 	 SELECT @TestId = WET_Id FROM Waste_Event_Type WHERE WET_Name = @WET_Name and WET_Id <> @WET_Id
 	 IF @TestId IS NOT NULL
 	 BEGIN
 	  	 RETURN(-100)
 	 END
 	 If Exists (select * from dbo.syscolumns where name = 'WET_Name_Local' and id =  object_id(N'[Waste_Event_Type]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Waste_Event_Type Set WET_Name_Global = ''' + replace(@WET_Name,'''','''''') + ''', ReadOnly = ' + Convert(nVarChar(10),@ReadOnly) + ' Where WET_Id = ' + Convert(nVarChar(10),@WET_Id)
     Else
 	  	 Select @Sql =  'Update Waste_Event_Type Set WET_Name_Local = ''' + replace(@WET_Name,'''','''''') + ''', ReadOnly = ' + Convert(nVarChar(10),@ReadOnly) + ' Where WET_Id = ' + Convert(nVarChar(10),@WET_Id)
 	 End
 	 Else
 	  	 Select @Sql =  'Update Waste_Event_Type Set WET_Name = ''' + replace(@WET_Name,'''','''''') + ''', ReadOnly = ' + Convert(nVarChar(10),@ReadOnly) + ' Where WET_Id = ' + Convert(nVarChar(10),@WET_Id)
 	 Execute(@Sql)
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
