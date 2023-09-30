
CREATE PROCEDURE dbo.spActivities_GetTest
@TestId	BIGINT


 AS 
	SELECT TestId = t.Test_Id, 
		LocationId = pu.PU_Id, 
		Location = pu.PU_Desc,
		DepartmentId = dpt.Dept_Id, 
		Department = dpt.Dept_Desc,
		LineId = pl.PL_Id, 
		Line = pl.PL_Desc,
		TestTime = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,'UTC'), 
		VarId = t.Var_Id, 
		VarDesc = v.Var_Desc, 
		EventId = t.Event_Id, 
		Result = t.Result,
		CommentId = t.Comment_Id, 
		ESignatureId = t.Signature_Id, 
		SecondUserId = t.Second_User_Id, 
		SecondUser = u2.Username, 
		Canceled = t.Canceled, 
		ArrayId = t.Array_Id, 
		IsLocked = t.Locked, 
		EntryOn = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,'UTC'), 
		EntryById = t.Entry_By, 
		EntryBy = u.Username, 
		DataTypeId = v.Data_Type_Id, 
		DataType = dt.Data_Type_Desc, 
		VarPrecision = v.Var_Precision
	FROM Tests t (nolock)
	JOIN Users u  (nolock)on u.User_Id = t.Entry_By

	JOIN Variables_Base v  (nolock) on v.Var_Id = t.Var_Id
	JOIN Data_Type dt  (nolock) on dt.Data_Type_Id = v.Data_Type_Id
	JOIN Prod_Units_Base pu  (nolock) on pu.PU_Id = v.PU_Id 
	JOIN Prod_Lines pl  (nolock) on pl.PL_Id = pu.PL_Id
	JOIN Departments dpt  (nolock) on dpt.Dept_Id  = pl.Dept_Id 
	LEFT JOIN Users u2  (nolock) on u2.User_Id = t.Second_User_Id
	WHERE t.Test_Id = @TestId

