CREATE PROCEDURE dbo.spEMCC_ByCalcIDUpdate
  @ListType int, @CalcID int, @User_Id int
AS
  DECLARE @Insert_Id integer 
  if @CalcId is null
    select @CalcId = 0
  INSERT INTO Audit_Trail(Application_Id, User_id, Sp_Name, Parameters, StartTime)
 	 VALUES (1, @User_Id, substring('spEMCC_CalcConfiguration',1,30),
            substring(
                convert(nVarChar(3),  @ListType) + ',' +
                convert(nvarchar(20), @CalcId)      + ',' +
                convert(nvarchar(20), @User_Id),
                      1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @ListType = 14
  delete from calculations where calculation_id = @CalcID
else if @ListType = 27
  delete from calculation_inputs where calculation_id = @CalcID
else if @ListType = 29 -- NEW_GUID ***
  begin 
    Delete from calculation_dependency_data 
      where calc_dependency_id in (select calc_dependency_id from calculation_dependencies where calculation_id = @CalcID)
    Delete from calculation_dependencies 
      where calculation_id = @CalcID
    Delete from calculation_input_data 
      where calc_input_id in (select calc_input_id from calculation_inputs where calculation_id = @CalcID)
    Delete from calculation_inputs 
      where calculation_id = @CalcID
    Delete From Calculation_Instance_Dependencies
      Where Result_Var_Id in (Select Var_Id From Variables where calculation_id = @CalcID)
    Update comments set shoulddelete = 1, comment = '' 
      where comment_id in (select comment_id from calculations where calculation_id = @CalcID)
    Update Variables_Base Set Ds_Id = 2, calculation_id = Null, SPC_Group_Variable_Type_Id = Null, SPC_Calculation_Type_Id = Null 
      where calculation_id = @CalcID
    Delete from calculations 
      where calculation_id = @CalcID
  end
else
  select Error = 'Error!!!'
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
  WHERE Audit_Trail_Id = @Insert_Id
