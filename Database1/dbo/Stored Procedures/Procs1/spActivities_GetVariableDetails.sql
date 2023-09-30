
CREATE PROCEDURE dbo.spActivities_GetVariableDetails @ActivityId     INT,
                                                     @VariableId     INT         = NULL,
                                                     @VariableFilter NVARCHAR(50) = NULL,
						     @UserId Int


AS
BEGIN
    DECLARE @ActivityTypeId INT, @Sheet_Id INT, @ActivityDesc NVARCHAR(1000), @VariableScrolling INT, @IsInclusiveSpecCalc INT, @KeyId DATETIME, @AliasColumnId INT
							 DECLARE @Variables TABLE(varId    INT,
VarOrder INT,
Title    NVARCHAR(50),
PUId     INT,
Group_id Int,
pug_Id int,DS_Id int,
Var_SGId int,
Var_Desc nvarchar(50),
User_Defined1 nvarchar(255),
User_Defined2 nvarchar(255),
User_Defined3 nvarchar(255),
Eng_Units nvarchar(15),
Data_Type_Id int,
Var_Precision tinyint,SPC_Calculation_Type_Id int,SPC_Group_Variable_Type_Id int, External_Link nvarchar(255),Input_Tag nvarchar(255)
)
    DECLARE @SheetId int,@UnitId int,@SheetAccess BIT,@VarIdAccess Bit,@Sheet_Group_Id Int,@UseDisplayOptions int
    SET @VariableFilter = REPLACE(REPLACE(REPLACE(REPLACE(@VariableFilter, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
    SET @VariableFilter = CASE
                              WHEN ISNULL(@VariableFilter, '') = ''
                              THEN '%'
                              ELSE '%'+@VariableFilter+'%'
                          END
    set @UseDisplayOptions = 0
    select @UseDisplayOptions = Value from Site_Parameters where Parm_iD = 95
-- Retrieve the Activity Type and some other values
    SELECT @ActivityTypeId = a.Activity_Type_Id,
           @ActivityDesc = a.Activity_Desc,
           @Sheet_Id = a.Sheet_Id,
           @KeyId = CASE
                        WHEN a.Activity_Type_Id = 2
                        THEN e.TimeStamp
                        ELSE a.KeyId
                    END
		    ,@UnitId = a.PU_Id
           FROM Activities AS a(nolock)
                LEFT JOIN Events AS e(nolock) ON e.Event_Id = a.KeyId1
           WHERE Activity_Id = @ActivityId

    SET @AliasColumnId = ISNULL((SELECT TOP 1 Value FROM dbo.Sheet_Display_Options(nolock) AS SDO WHERE SDO.Display_Option_Id = 458
                                                                                                        AND SDO.Sheet_Id = @Sheet_Id), 0);
    SET @VariableScrolling = ISNULL((SELECT TOP 1 Value FROM Sheet_Display_Options(nolock) WHERE Sheet_Id = @Sheet_Id
                                                                                                 AND Display_Option_Id = 449), 1);

    SET @IsInclusiveSpecCalc = ISNULL((SELECT TOP 1 Value FROM Site_Parameters WHERE Parm_Id = 13), 1)
    SET @SheetAccess = 0
    IF @ActivityId IS NOT NULL
    Begin

    	Select @SheetAccess = dbo.fnActivities_CheckSheetSecurityForActivities(@Sheet_Id, 454, 2, @UnitId, @UserId)

	Select @Sheet_Group_Id = Group_Id from sheets  where sheet_id = @Sheet_Id
    End
    IF isnull(@VariableId, 0) = 0 -- Return all variables
        BEGIN
            INSERT INTO @Variables(varId, VarOrder, Title)
            SELECT * FROM dbo.fnActivities_GetVariablesForActivity(@ActivityId)
        END
        ELSE -- Return single variable
        BEGIN
            INSERT INTO @Variables( VarId,
                                    VarOrder )
            SELECT @VariableId,
                   1
        END
		UPDATE V SET 
			V.PUId = COALESCE(PUB.Master_Unit, PUB.PU_Id) ,
			V.Group_id = VB.Group_Id,
			V.pug_Id =VB.PUG_Id ,
			V.DS_Id = VB.DS_Id,
			--V.Var_SGId = VB.var,
			V.SPC_Calculation_Type_Id = VB.SPC_Calculation_Type_Id,
			V.Var_Desc  = VB.Var_Desc,
			V.User_Defined1 = VB.User_Defined1,
			V.User_Defined2 = VB.User_Defined2,
			V.User_Defined3 = VB.User_Defined3,
			V.Eng_Units = VB.Eng_Units,
			V.Data_Type_Id = VB.Data_Type_Id,
			V.Var_Precision = VB.Var_Precision	,
			V.SPC_Group_Variable_Type_Id = VB.SPC_Group_Variable_Type_Id
			,V.External_Link = VB.External_Link
			,V.Input_Tag = VB.Input_Tag
		FROM @Variables V
            JOIN Variables_Base VB wITH (nolock) ON V.VarId = VB.Var_Id
            JOIN Prod_Units_Base PUB WITH (nolock) ON PUB.PU_Id = VB.PU_Id

		 IF EXISTS(SELECT TOP 1 Activity_Id FROM Activities)
		   AND (SELECT COUNT(DISTINCT PUId) FROM @Variables) > 1
			BEGIN
				SELECT Code = 'InvalidData',
					   Error = 'Error - Mixed  Units not currently supported',
					   ErrorType = 'MixedUnits',
					   PropertyName1 = 'PuId',
					   PropertyName2 = '',
					   PropertyName3 = '',
					   PropertyName4 = '',
					   PropertyValue1 = '',
					   PropertyValue2 = '',
					   PropertyValue3 = '',
					   PropertyValue4 = ''
				RETURN
			END
			declare @DBZone varchar(100)
 SELECT TOP 1 @DBZone = Value FROM site_parameters WHERE parm_id = 192;

    IF(SELECT COUNT(0) FROM @Variables) > 0
        BEGIN
;WITH Vars as (
		Select 
			V.Group_Id Var_SGId,V.VarId,V.pug_Id,Pg.Group_Id VarGrp_SGId
			,Sg.Group_Desc VariableSecurityGrp,Pg.PUG_Desc VariableGroup
			,SPg.Group_Desc VariableGroupLvlSecurityGrp,V.DS_Id
		from 
			--Variables_Base V
			--Join 
			@Variables V --on Vars.VarId = V.Var_Id
			Left join pu_Groups Pg WITH (nolock) on Pg.PUG_Id = V.PUG_Id
			Left JOIN Security_Groups Sg WITH (nolock)  on Sg.Group_Id = V.Group_Id
			LEFT JOIN Security_Groups Spg  WITH (nolock) on Spg.Group_Id = Pg.Group_Id

		),
		TmpUsers As (
		Select 
			u.Username ,Sg.Group_Desc,Al.AL_Desc,Al.AL_Id,us.Group_Id User_SGId,u.User_Id
		from 
			Users_Base u
			Join User_Security us on us.User_Id = u.User_Id
			Left join Security_Groups Sg on Sg.Group_Id = us.Group_Id
			Left join Access_Level Al on Al.AL_Id = us.Access_Level
		Where u.User_Id = @UserId
		)
				
,TmpUsersMinGrp as (Select User_Id,User_SGId,Min(AL_Id) Min_Al_Id from TmpUsers Group by User_Id , User_SGId )
,TmpUsersMin As (

Select * from (

Select Min_Al_Id,@UserId User_Id,User_SGId UserSGId from TmpUsersMinGrp Where User_SGId = 1
UNION
Select Min_Al_Id,@UserId User_Id,User_SGId UserSGId from 
(Select Row_Number() over (Order by Min_Al_Id) rownum,Min_Al_Id, User_SGId From TmpUsersMinGrp Where User_SGId != 1) T
Where T.rownum = 1) T1 
Where Exists (Select 1 from TmpUsersMinGrp Where User_SGId = 1)
UNION
Select Min_Al_Id,@UserId User_Id,User_SGId UserSGId from TmpUsersMinGrp Where not exists 
(Select 1 from  TmpUsersMinGrp Where User_SGId = 1)

)
		,Final As ( 
		Select 
		V.Varid Var_Id,
		CASE WHEN @UserId IS NULL THEN 1 ELSE 
			 
				CASE 
					WHEN v.Var_SGId IS NOT NULL
					THEN
						CASE 
							WHEN EXISTS(SELECT 1 FROM TmpUsers Where User_Id = @UserId and AL_Id > 1 and Group_Desc ='Administrator') 
							THEN 1
						ELSE
							CASE 
								WHEN 
								@SheetAccess = 1 AND
								(
									EXISTS
									(
										SELECT 1 FROM Vars v1 
										join TmpUsers u1 on v1.Var_SGId = u1.User_SGId And ((V1.DS_Id in (3,16) AND u1.AL_Id = 4) OR (V1.DS_Id NOT in (3,16) AND u1.AL_Id > 1))  
										join TmpUsersMin TMin on TMin.User_Id = u1.User_Id  And ((V1.DS_Id in (3,16) AND (Min_Al_Id = 4 AND TMin.UserSGId=ISNULL(@Sheet_Group_Id,u1.User_SGId))) OR (V1.DS_Id NOT in (3,16) AND Min_Al_Id > 1 AND TMin.UserSGId=ISNULL(@Sheet_Group_Id,u1.User_SGId) ))
										where V1.varId = V.varId 
									)
									OR
									 EXISTS
									(
										SELECT 1 FROM Vars v1 
										join TmpUsers u1 on v1.Var_SGId = u1.User_SGId And ((V1.DS_Id in (3,16) AND u1.AL_Id = 4) OR (V1.DS_Id NOT in (3,16) AND u1.AL_Id > 1))  
										where V1.VarId = V.VarId AND (v.Var_SGId != @Sheet_Group_Id
										AND Not exists (Select 1 from TmpUsers Where User_SGId = 1 ))
									) 
								)
								THEN 1
							ELSE 
								0
							END
						END
				ELSE
					CASE 
						WHEN 
						(
							(
								@SheetAccess = 1 AND V.DS_Id not in (3,16) 
								AND 
								(
									(
										Exists
										(
											Select 1 from TmpUsers u1 Join TmpUsersMin T1 on T1.User_id = u1.User_Id  Where u1.User_Id = @UserId And 
												(
													(T1.UserSGId = 1 AND T1.Min_Al_Id >1 /*AND u1.User_SGId = @Sheet_Group_Id*/ AND u1.Al_Id > 1)
														or
													(T1.UserSGId != 1 AND T1.Min_Al_Id >1 AND (u1.User_SGId = @Sheet_Group_Id or @Sheet_Group_Id is null) AND u1.Al_Id > 1)
												)
										) AND @UseDisplayOptions = 1
									)
									OR 
									(
										Exists(Select 1 from TmpUsers u1 Join TmpUsersMin T1 on T1.User_id = u1.User_Id  Where u1.User_Id = @UserId And AL_Id >=1 and T1.Min_Al_Id >=1) and @UseDisplayOptions = 0

									)
									OR
									(
										@UseDisplayOptions = 0 AND NOT EXISTS(SELECT 1 FROM TmpUsers where User_Id = @UserId ) AND @Sheet_Group_Id IS NULL
									)
								)
						
							)
						OR
						(@SheetAccess = 1 AND V.DS_Id in (3,16) AND 
						
						(
						(EXISTS (SELECT 1 From TmpUsers  u1  Where u1.User_Id = @UserId And (AL_Id =4 and (User_SGId = @Sheet_Group_Id or @Sheet_Group_Id is null))) and @UseDisplayOptions = 1 )
						OR 
						(EXISTS (SELECT 1 From TmpUsers Where User_Id = @UserId And AL_Id > 1 and Group_Desc ='Administrator') and (@UseDisplayOptions = 0 OR @UseDisplayOptions = 1)  )
						)
						
						)
						)
						 THEN 1 
					ELSE
						0
					END
				END
			END 
			
			IsEditable
					
		from Vars v)
            SELECT ActivityId = @ActivityId,
                   ActivityDesc = @ActivityDesc,
                   Title = ISNULL(v.Title, ''),
                   VarId = v.VarId,
                   TestId = t.Test_Id,
                   VarDesc = v.Var_Desc,
                   VariableName = CASE @AliasColumnId
                                      WHEN 0
                                      THEN V.Var_Desc
                                      WHEN 1
                                      THEN ISNULL(V.User_Defined1, V.Var_Desc)
                                      WHEN 2
                                      THEN ISNULL(V.User_Defined2, V.Var_Desc)
                                      WHEN 3
                                      THEN ISNULL(V.User_Defined3, V.Var_Desc)
                                  END,
                   EngineeringUnits = v.Eng_Units,
                   DataTypeId = v.Data_Type_Id,
                   DataType = dt.Data_Type_Desc,
                   IsUserDefined = dt.User_Defined,
                   DataSourceId = v.DS_Id,
                   DataSource = ds.DS_Desc,
                   VarPrecision = v.Var_Precision,
                   VarOrder = v.VarOrder,
                   t.Result,
                   ExternalLink = ISNULL(v.External_Link, PUG.External_Link),
                   VariableScrolling = CAST(CASE
                                                WHEN @VariableScrolling = 1
                                                THEN 1
                                                ELSE 0
                                            END AS BIT),
                   IsInclusiveSpecCalc = CAST(CASE
                                                  WHEN @IsInclusiveSpecCalc = 1
                                                  THEN 0
                                                  ELSE 1
                                              END AS BIT),
                   LocationId = pu.PU_Id,
                   Location = pu.PU_Desc,
                   DepartmentId = dpt.Dept_Id,
                   Department = dpt.Dept_Desc,
                   LineId = pl.PL_Id,
                   Line = pl.PL_Desc,
                   TestTime = --dbo.fnServer_CmnConvertFromDbTime(t.Result_On, 'UTC'),
				   t.Result_On at time zone @DBZone at time zone 'UTC' ,
                   EventId = t.Event_Id,
                   CommentId = t.Comment_Id,
                   ESignatureId = t.Signature_Id,
                   SecondUserId = t.Second_User_Id,
                   SecondUser = u2.Username,
                   Canceled = t.Canceled,
                   ArrayId = t.Array_Id,
                   IsLocked = t.Locked,
                   EntryOn = --dbo.fnServer_CmnConvertFromDbTime(t.Entry_On, 'UTC'),
				   t.Entry_On at time zone @DBZone at time zone 'UTC' ,
                   EntryById = t.Entry_By,
                   EntryBy = u.Username,
				   SheetId = @Sheet_Id,
				   f.IsEditable,
				   InputTag = v.Input_Tag
				   ,ISNULL(t.IsVarMandatory,0) IsVarMandatory
				   ,CT.SPC_Calculation_Type_Id
				   ,CT.SPC_Calculation_Type_Desc
				   ,GVT.spc_Group_variable_type_id
				   ,GVT.SPC_Group_Variable_Type_Desc
                   FROM --@Variables AS v1
                        --JOIN 
						@Variables AS V  
                        JOIN Final f on f.Var_Id = v.VarId
			JOIN PU_Groups AS PUG WITH (nolock) ON v.PUG_Id = PUG.PUG_Id
                        JOIN Data_Type AS dt WITH (nolock) ON dt.Data_Type_Id = v.Data_Type_Id
                        JOIN Data_Source AS ds WITH (nolock) ON ds.DS_Id = v.DS_Id
                        LEFT JOIN Tests AS t WITH (nolock) ON t.Var_Id = v.VarId
                                                        AND t.Result_On = @KeyId
                        LEFT JOIN Users AS u WITH (nolock) ON u.User_Id = t.Entry_By
                        LEFT JOIN Users AS u2 WITH (nolock) ON u2.User_Id = t.Second_User_Id
                        JOIN Prod_Units_Base AS pu WITH (nolock) ON pu.PU_Id = v.PUId
                        JOIN Prod_Lines AS pl WITH (nolock) ON pl.PL_Id = pu.PL_Id
                        JOIN Departments AS dpt WITH (nolock) ON dpt.Dept_Id = pl.Dept_Id
                                                           AND COALESCE(@ActivityTypeId, 0) > 0 -- valid activity was found
						LEFT JOIN SPC_Calculation_Types AS CT WITH (nolock) ON v.SPC_Calculation_Type_Id = CT.SPC_Calculation_Type_Id
						LEFT JOIN SPC_Group_Variable_Types AS GVT WITH (nolock) ON v.SPC_Group_Variable_Type_Id = GVT.SPC_Group_Variable_Type_Id
						where 
						 CASE @AliasColumnId
                                                                    WHEN 0
                                                                    THEN V.Var_Desc
                                                                    WHEN 1
                                                                    THEN ISNULL(V.User_Defined1, V.Var_Desc)
                                                                    WHEN 2
                                                                    THEN ISNULL(V.User_Defined2, V.Var_Desc)
                                                                    WHEN 3
                                                                    THEN ISNULL(V.User_Defined3, V.Var_Desc)
                                                                END LIKE @VariableFilter ESCAPE '\'
                                                           
                   ORDER BY v.VarOrder
        END
END

