
CREATE PROCEDURE dbo.spActivities_GetSheetSecurity @SheetList nVARCHAR(MAX), -- Sheet Ids seperated by a comma
                                                   @UserId    INT -- User Id

AS
BEGIN

    IF @SheetList IS NOT NULL
        BEGIN
			DECLARE @SheetIdList INTEGERTABLETYPE
			Declare @IsUserinAdminGroup int,@IsUserAdminInAdminGroup int
			Select @IsUserinAdminGroup= 0 ,@IsUserAdminInAdminGroup =0
			SELECT @IsUserinAdminGroup = 1 FROM User_Security WITH(NOLOCK) WHERE Group_Id = 1 AND USer_Id = @UserId AND Access_Level > 1
			SELECT @IsUserAdminInAdminGroup = 1 FROM User_Security WITH(NOLOCK) WHERE Group_Id = 1 AND USer_Id = @UserId AND Access_Level =4

			Create table #UserSecurity(Access_Level int,User_Id int,Group_Id int)
			Insert into #UserSecurity
			Select Access_Level,User_Id,Group_Id from User_security where user_Id = @UserId


            INSERT INTO @SheetIdList
            SELECT Item FROM dbo.fnCMN_SplitString(@SheetList, ',');
			;WITH CTE_Sheets AS(
			SELECT SL.Item AS SheetId,
                        S.Sheet_Type,
                        CASE WHEN S.Sheet_Type = 1 THEN SDO1.Value ELSE S.Master_Unit END Master_Unit,
                        SDO.Display_Option_Id,
                        SDO.Value,
						(CASE ISNULL(SDO2.Value, 0) WHEN 0 THEN 0 ELSE CASE when @IsUserinAdminGroup=1 THEN 0 ELSE 1 END END) LockUnavailableCells
						,coalesce(s.Group_Id, sg.Group_Id) GroupID
						,COALESCE(SDOAddSecurity.Value,SDODefaultAddSecurity.Display_Option_Default,3) [SDOAddSecurityValue]
						,COALESCE(SDOOverrideLockSecurity.Value,SDODefaultOverrideLockSecurity.Display_Option_Default,3) [SDOOverrideLockSecurityValue]
						,Case when coalesce(s.Group_Id, sg.Group_Id) is null OR @IsUserAdminInAdminGroup = 1 then 4 else (select Coalesce(Access_Level, 0) From #UserSecurity where User_Id = @UserId and Group_Id = coalesce(s.Group_Id, sg.Group_Id)) end [UserSecurityValue]
                        FROM @SheetIdList AS SL
                             JOIN Sheets AS S WITH(NOLOCK) ON S.Sheet_Id = SL.Item
                             JOIN Sheet_Display_Options AS SDO WITH(NOLOCK) ON SDO.Sheet_Id = S.Sheet_Id
							 Left join Sheet_Display_Options AS SDO1 WITH(NOLOCK) ON SDO1.Sheet_Id = S.Sheet_Id and SDO1.Display_Option_Id = 446
							 Left join Sheet_Display_Options AS SDO2 WITH(NOLOCK) ON SDO2.Sheet_Id = S.Sheet_Id and SDO2.Display_Option_Id = 151
							 LEFT join Sheet_Display_Options As SDOAddSecurity WITH(NOLOCK) on SDOAddSecurity.Sheet_Id = S.Sheet_Id and SDOAddSecurity.Display_Option_Id = 8
							 LEFT JOIN Sheet_Type_Display_Options as SDODefaultAddSecurity WITH(NOLOCK) on SDODefaultAddSecurity.Display_Option_Id = 8 and SDODefaultAddSecurity.Sheet_Type_Id = S.Sheet_Type
							 LEFT join Sheet_Display_Options As SDOOverrideLockSecurity WITH(NOLOCK) on SDOOverrideLockSecurity.Sheet_Id = S.Sheet_Id and SDOOverrideLockSecurity.Display_Option_Id = 454
							 LEFT JOIN Sheet_Type_Display_Options as SDODefaultOverrideLockSecurity WITH(NOLOCK) on SDODefaultOverrideLockSecurity.Display_Option_Id = 452 and SDODefaultOverrideLockSecurity.Sheet_Type_Id = S.Sheet_Type
							 LEFT join Sheet_groups sg WITH(NOLOCK) ON s.Sheet_Group_Id = sg.Sheet_Group_Id 
			),CTE_SheetPermissions as(
			Select Distinct
			SheetId, case when [UserSecurityValue] >=[SDOAddSecurityValue] then 1 else 0 end AddSecurity,
			case when [UserSecurityValue] >=[SDOOverrideLockSecurityValue] then 1 else 0 end OverrideLockSecurity,LockUnavailableCells
			from CTE_Sheets)
			 SELECT SheetId,
                        P.PermissionName,
                        P.PermissionValue
                        FROM CTE_SheetPermissions UNPIVOT(PermissionValue FOR PermissionName IN(AddSecurity,
                        																		OverrideLockSecurity,
                                                                                                LockUnavailableCells)) AS P
                        ORDER BY SheetId,
                                 PermissionName
			Drop table #UserSecurity         
		 
		END
END
