CREATE PROCEDURE dbo.spEMCC_ByIDUpdate
  @ListType int, 
  @id int, 
  @User_Id int,
  @IsAlias  	  	 Int = 0
AS
  DECLARE @Insert_Id integer 
  if @id is null
    select @id = 0
Select @IsAlias = Coalesce(@IsAlias,0)
  INSERT INTO Audit_Trail(Application_Id, User_id, Sp_Name, Parameters, StartTime)
 	 VALUES (1, @User_Id, substring('spEMCC_ByIDUpdate',1,30),
            substring(
                convert(nVarChar(3),  @ListType) + ',' +
                convert(nvarchar(20), @Id)      + ',' +
                convert(nvarchar(20), @User_Id),
                      1,255),
            dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @ListType = 34
  begin
    delete from calculation_dependency_data where calc_dependency_id = @id
    delete from calculation_dependencies where calc_dependency_id = @id
  end
else if @ListType = 40
  begin
    delete from calculation_dependency_data where Calc_Dependency_Id = @id
    delete from calculation_dependencies where Calc_Dependency_Id = @id
  end
else if @ListType = 41
  begin
    delete from calculation_input_data where calc_input_id = @id
    delete from calculation_inputs where calc_input_id = @id
  end
else if @ListType = 80
  begin
    delete from calculation_input_data where calc_input_id = @id
    delete from calculation_inputs where calc_input_id = @id
  end
else if @ListType = 81
  delete from calculation_input_data where calc_input_id = @id
else
  select Error = 'Error!!!'
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
   WHERE Audit_Trail_Id = @Insert_Id
