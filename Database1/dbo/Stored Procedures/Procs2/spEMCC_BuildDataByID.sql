CREATE PROCEDURE dbo.spEMCC_BuildDataByID
  @ListType int, @id1 int, @id2 int, @id3 int, @str1 nvarchar(255), @User_Id int
AS
  DECLARE @Insert_Id integer 
  if @id1 is null
    select @id1 = 0
  if @id2 is null
    select @id2 = 0
  if @id3 is null
    select @id3 = 0
/* @Str1 Never used ???**/
--  if @str1 is null
--    select @str1 = '(null)'
  INSERT INTO Audit_Trail(Application_Id, User_id, Sp_Name, Parameters, StartTime)
 	 VALUES (1, @User_Id, substring('spEMCC_CalcConfiguration',1,30),
            substring(
                convert(nVarChar(3), @ListType) + ',' +
                convert(nvarchar(20), @Id1)      + ',' +
                convert(nvarchar(20), @Id2)      + ',' +
                convert(nvarchar(20), @Id3)      + ',' +
                convert(nvarchar(20), @User_Id),1,255),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @ListType = 34
  begin
    delete from calculation_dependency_data where calc_dependency_id = @id1
    delete from calculation_dependencies where calc_dependency_id = @id1
  end
else if @ListType = 84 -- DEPENDENCY DEFAULTS --
  begin
    delete from calculation_instance_dependencies Where Result_Var_Id = @id1 and Var_Id = @id2
    insert into calculation_instance_dependencies( Result_Var_Id, Var_Id, Calc_Dependency_Scope_Id) values(@id1, @id2, 2)
  end
else if @ListType = 86
  begin
    if @id1 = 0 
      delete from calculation_instance_dependencies where result_var_id = @id2 and var_id = @id3
    else
      delete from calculation_dependency_data where calc_dependency_id = @id1 and result_var_id = @id2
  end
else if @ListType = 87
  delete from calculation_input_data where calc_input_id = @id1 and result_var_id = @id2
else
  select Error = 'Error!!!'
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
  WHERE Audit_Trail_Id = @Insert_Id
