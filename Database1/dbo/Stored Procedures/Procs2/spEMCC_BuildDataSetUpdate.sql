CREATE PROCEDURE dbo.spEMCC_BuildDataSetUpdate
  @ListType int, @CalcId int, @id1 int, @id2 int, @id3 int, @str1 nvarchar(255), @str2 nvarchar(255), @User_Id int
AS
  DECLARE @Insert_Id integer
  DECLARE @OldCalc_Id integer 
  DECLARE @str4 nvarchar(255)
  if @id1 is null
    select @id1 = 0
  if @id2 is null
    select @id2 = 0
  if @id3 is null
    select @id3 = 0
  INSERT INTO Audit_Trail(Application_Id, User_id, Sp_Name, Parameters, StartTime)
 	 VALUES (1, @User_Id, substring('spEMCC_BuildDataSetUpdate',1,30),
            substring(coalesce(convert(nVarChar(3), @ListType),'(null)') + ',' +
                coalesce(convert(nvarchar(20), @Id1),'(null)')      + ',' +
                coalesce(convert(nvarchar(20), @Id2),'(null)')      + ',' +
                coalesce(convert(nvarchar(20), @Id3),'(null)')      + ',' +
                coalesce(ltrim(rtrim(@Str1)),'(null)')             + ',' +
                coalesce(ltrim(rtrim(@Str2)),'(null)')             + ',' +
                convert(nvarchar(20), @User_Id),1,255),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @ListType = 28
  begin
    if @id3 > 0 
      begin
        update calculation_dependencies set calculation_id = @CalcId, name = convert(nvarchar(50), @str2),
               calc_dependency_scope_id = @id1, optional = convert(bit,@id2) where calc_dependency_id = @id3
        select calc_dependency_id = @id3
      end
    else
      begin
        insert into calculation_dependencies 
          (calculation_id, name, calc_dependency_scope_id, optional)
          values(@CalcId, convert(nvarchar(50), @str2), @id1, convert(bit, @id2))
        select calc_dependency_id = Scope_Identity()
      end
  end
else if @ListType = 35
  begin
    if @id3 = 0
      select @id3 = null
    if @str1 = ''
      select @str1 = null
    If @str1 is null 
       Select @str1 = Default_Value From calculation_inputs Where calc_input_id = @id1
       Select @str4 = Test_Name from Variables where var_Id = @id3
       Delete from calculation_input_data where calc_input_id = @id1 and result_var_id = @id2
       Insert into calculation_input_data(calc_input_id, result_var_id, member_var_id, default_value, alias_name)
            values(@id1, @id2, @id3, @str1, @str4)
  End
else if @ListType = 36
  begin
    if @id3 = 0
      select @id3 = null
    if @str1 = ''
      select @str1 = null
    If @str1 is null 
       Select @str1 = Equipment_Type From Prod_Units Where PU_id = @id3
       Delete from calculation_input_data where calc_input_id = @id1 and result_var_id = @id2
       Insert into calculation_input_data(calc_input_id, result_var_id, PU_Id, alias_name)
            values(@id1, @id2, @id3, @str1)
  End
else if @ListType = 83
  begin
    if @id3 = 0 
      begin
        delete from calculation_instance_dependencies where result_var_id = @id1 and var_id = convert(int, @str1)
        insert into calculation_instance_dependencies (result_var_id, var_id, calc_dependency_scope_id) values (@id1, @id2, 2)
      end
    else
      begin
        if (select count(Calc_Dependency_Id) from calculation_dependency_data where calc_dependency_id = @id3 and result_var_id = @id1) > 0
          update calculation_dependency_data set var_id = @id2 where calc_dependency_id = @id3 and result_var_id = @id1
       else
          insert into calculation_dependency_data (calc_dependency_id, var_id, result_var_id) values(@id3, @id2, @id1)
      end
  end
else if @ListType = 94
  begin
 	 Select @OldCalc_Id = Null
 	 Select @OldCalc_Id = calculation_id from variables where var_id = @id1
 	 if @id2 = 0 	 select @id2 = Null
 	 if @id3 = 0  	 select @id3 = Null
 	 If @OldCalc_Id Is not null
 	   Begin
 	  	  	 If @CalcId <> @OldCalc_Id
 	  	  	   Begin
 	  	  	  	   Execute spEM_DropCalc @id1, 0, @User_Id
 	  	  	   End
 	  	   End
 	 If @id1 <> 0
   	  	 Update variables_Base
    	  	  set calculation_id = @CalcId, DS_Id = 16, SPC_Calculation_Type_Id = @id2, Spec_Id = Coalesce(@id3, Spec_Id),
         	  	 SPC_Group_Variable_Type_Id = Case When @Id2 = 2 or @Id2 = 3 then 6
  	  	  	  	  	  	  	 When @Id2 is NULL then Coalesce(@Id2, SPC_Group_Variable_Type_Id)
 	  	  	  	  	  	  	 Else 5
 	  	  	  	  	  	  	 End
 	    	 where var_id = @id1 
    select calculation_id = @CalcId
  end
else
  select Error = 'Error!!!'
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
