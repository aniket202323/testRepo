-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spWO_SearchVariables
-----------------------------------------------------------
CREATE procedure [dbo].[spWO_SearchVariablesSPC]
@LineId int = null,
@UnitId int = null,
@GroupId int = null,
@NameMask nVarChar(50) = null,
@UserId int = NULL
--WITH ENCRYPTION 
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
/***************************
This sp returns all variables, regardless type and is used from SPC Chart Report.
-- For Testing
--***************************
Select @UnitId = 2
Select @UserId = 1
Select @GroupId = 3
Select @NameMask = 'PM1'
--***************************/
If @GroupId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              v.Var_desc like '%' + @NameMask + '%' and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else If @UnitId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              v.Var_desc like '%' + @NameMask + '%' and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else If @LineId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              v.Var_desc like '%' + @NameMask + '%' and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.Var_desc like '%' + @NameMask + '%'  and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where ((v.group_id is null) or (s.Access_level >= 1))
  End
