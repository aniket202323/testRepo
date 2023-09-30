CREATE PROCEDURE dbo.spEM_DropDepartment
  @Dept_Id int,
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropDepartment',
                 convert(nVarChar(10),@Dept_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  DELETE FROM PAEquipment_Aspect_SOAEquipment WHERE Dept_Id = @Dept_Id
  DELETE FROM Departments_Base   WHERE Dept_Id = @Dept_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
