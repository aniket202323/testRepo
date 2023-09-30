create procedure [dbo].[spS88R_SearchBatchVariables]
@LineId int = null,
@UnitId int = null,
@GroupId int = null,
@NameMask nVarChar(50) = null,
@UserId int = NULL
AS
/***************************
-- For Testing
--***************************
Select @UnitId = 2
Select @UserId = 1
Select @GroupId = 3
Select @NameMask = 'PM1'
--***************************/
Declare @PhaseSubTypeId Int
Select @PhaseSubTypeId = Event_Subtype_Id
From Event_SubTypes
Where Event_Subtype_Desc = 'Phase'
If @GroupId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
  End
Else If @UnitId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
  End
Else If @LineId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
  End
Else
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.Var_desc like '%' + @NameMask + '%'  and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1)) and
 	  	  	  	  	  	  	 v.Event_Type = 14 And v.Event_SubType_Id = @PhaseSubTypeId
  End
