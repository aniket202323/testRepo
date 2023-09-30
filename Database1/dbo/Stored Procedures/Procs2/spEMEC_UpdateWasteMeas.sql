Create Procedure dbo.spEMEC_UpdateWasteMeas
@WEMT_Id int = Null,
@WEMT_Name nVarChar(100),
@Conversion real,
@Conversion_Spec int,
@PU_Id int,
@User_Id int
AS
Declare @Insert_Id int, @Sql nvarchar(1000)
DECLARE @Test Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateWasteMeas',
 	  	  	 Isnull(Convert(nVarChar(10),@WEMT_Id),'Null') + ','  + 
 	  	  	 Isnull(@WEMT_Name,'Null') + ','  + 
 	  	  	 Isnull(Convert(nVarChar(10),@Conversion),'Null') + ','  + 
 	  	  	 Isnull(Convert(nVarChar(10),@Conversion_Spec),'Null') + ','  + 
 	  	  	 Isnull(Convert(nVarChar(10),@PU_Id),'Null') + ','  + 
 	  	  	 Isnull(Convert(nVarChar(10),@User_Id),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Conversion_Spec = 0
  select @Conversion_Spec = Null
if @WEMT_Id is Null
BEGIN
 	 Select @WEMT_Id = WEMT_Id From Waste_Event_Meas Where WEMT_Name = @WEMT_Name and PU_Id = @PU_Id 
 	 IF @WEMT_Id is Not Null
 	 BEGIN
 	  	 RETURN(-100)
 	 END
 	 If Exists (select * from dbo.syscolumns where name = 'WEMT_Name_Local' and id =  object_id(N'[Waste_Event_Meas]'))
 	 BEGIN
 	  	 Select @Sql = 'INSERT INTO Waste_Event_Meas(PU_Id, WEMT_Name_Local, Conversion, Conversion_Spec)'
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @Sql = 'INSERT INTO Waste_Event_Meas(PU_Id, WEMT_Name, Conversion, Conversion_Spec)'
 	 END
 	 Select @Sql = @Sql + ' VALUES(' + Convert(nVarChar(10),@PU_Id)+ ',' + '''' + replace(@WEMT_Name,'''','''''') + ''','
 	 Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Conversion),'Null') + ',' + Coalesce(Convert(nVarChar(10),@Conversion_Spec),'Null') + ')'
 	 Execute(@Sql)
END
ELSE
BEGIN
 	 SELECT @Test = WEMT_Id FROM Waste_Event_Meas Where WEMT_Name = @WEMT_Name AND PU_Id = @PU_Id AND WEMT_Id <> @WEMT_Id
 	 IF @Test IS NOT NULL 
 	 BEGIN
 	  	 RETURN(-100)
 	 END
 	 If Exists (select * from dbo.syscolumns where name = 'WEMT_Name_Local' and id =  object_id(N'[Waste_Event_Meas]'))
 	 BEGIN
 	  	 If (@@Options & 512) = 0
 	  	  	 Select @Sql =  'Update Waste_Event_Meas Set WEMT_Name_Global = ''' + replace(@WEMT_Name,'''','''''') + ''', Conversion = ' + Coalesce(Convert(nVarChar(10), @Conversion), 'Null') + ', Conversion_Spec = ' + Coalesce(Convert(nVarChar(10),@Conversion_Spec), 'Null') + ' Where WEMT_Id = ' + Convert(nVarChar(10),@WEMT_Id)
 	  	 Else
 	  	  	 Select @Sql =  'Update Waste_Event_Meas Set WEMT_Name_Local = ''' + replace(@WEMT_Name,'''','''''') + ''', Conversion = ' + Coalesce(Convert(nVarChar(10), @Conversion), 'Null') + ', Conversion_Spec = ' + Coalesce(Convert(nVarChar(10),@Conversion_Spec), 'Null') + ' Where WEMT_Id = ' + Convert(nVarChar(10),@WEMT_Id)
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @Sql =  'Update Waste_Event_Meas Set WEMT_Name = ''' + replace(@WEMT_Name,'''','''''') + ''', Conversion = ' + Coalesce(Convert(nVarChar(10), @Conversion), 'Null') + ', Conversion_Spec = ' + Coalesce(Convert(nVarChar(10),@Conversion_Spec), 'Null') + ' Where WEMT_Id = ' + Convert(nVarChar(10),@WEMT_Id)
 	 END
 	 Execute(@Sql)
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
