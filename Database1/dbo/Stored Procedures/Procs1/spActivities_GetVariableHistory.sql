
CREATE PROCEDURE dbo.spActivities_GetVariableHistory @ActivityId        INT,
                                                     @DirectionBackward BIT = NULL,
                                                     @SameProduct       BIT = NULL,
                                                     @IsInclusive       BIT = NULL,
                                                     @Size              INT = NULL,
													 @UserId INT = NULL


AS
BEGIN

    DECLARE @PUID INT, @SheetId INT, @VariableScrolling BIT, @IsInclusiveSpecCalc BIT, @Title NVarchar(50), @ActivityTypeId INT, @AliasColumnId INT
    DECLARE @KeyId DATETIME, @KeyId1 INT, @MaxTime DATETIME, @MinTime DATETIME
    DECLARE @LoopStart INT, @LoopEnd INT, @LoopProdId INT, @LoopNextProdId INT
    DECLARE @ActivityProductId INT, @ActivityEndTime DATETIME, @Start_Id INT
    DECLARE @IsInclusiveSpecs INT
    Declare @ActivityStatus int, @GraceTimeToEdit int
    Declare @DBZone varchar(100)
    Select @DBZone=value from site_parameters where Parm_id = 192
	
	DECLARE @Variables TABLE(varId    INT,
                             VarOrder INT,
                             Title    NVarchar(50),
                             PUId     INT,
							
Var_Desc nvarchar(50),
User_Defined1 nvarchar(255),
User_Defined2 nvarchar(255),
User_Defined3 nvarchar(255),
Eng_Units nvarchar(15),
Data_Type_Id int,
Var_Precision tinyint,
pu_desc nvarchar(200),
pl_desc nvarchar(200),
pl_id int,
dept_id int,
dept_desc nvarchar(200),
ProductStartTime DateTime,
SA_Id tinyint, Sampling_Interval int, esignatureLevel int,
Test_Freq	int,
AS_Id	int,
L_Warning nvarchar(25),
L_Reject nvarchar(25),
L_Entry	nvarchar(25),
U_User	nvarchar(25),
Target	nvarchar(25),
L_User	nvarchar(25),
U_Entry	nvarchar(25),
U_Reject	nvarchar(25),
U_Warning	nvarchar(25),
Esignature_Level	int,
L_Control	nvarchar(25),
T_Control	nvarchar(25),
U_Control	nvarchar(25)

)

    CREATE TABLE #ActivityData (Id                    INT IDENTITY(1, 1),
                                ActivityId            INT,
                                ActivityDesc          nVARCHAR(1000),
                                ActivityDisplayTypeId INT,
                                ProdId                INT,
                                ActivityTypeId        INT,
                                SheetId               INT,
                                KeyId1                INT,
                                KeyID                 DATETIME,
                                StartTime             DATETIME,
                                EndTime               DATETIME,
                                GradeChanged          INT,
                                OriginalProdId        INT,
								ProductStartTime Datetime)
    DECLARE @ProductionStartsData TABLE(StartTime DATETIME,
                                        EndTime   DATETIME,
                                        ProdId    INT)

--Default Values

	Declare @UserAccess INT, @Sheet_Group_Id INT
	SET @UserAccess = 1
	
    SET @DirectionBackward = ISNULL(@DirectionBackward, 1)
    SET @IsInclusive = ISNULL(@IsInclusive, 0)
    SET @Size = ISNULL(@Size, 10)
    SET @SameProduct = ISNULL(@SameProduct, 0)

    SELECT @KeyId = KeyId,
           @KeyId1 = KeyId1,
           @SheetId = Sheet_Id,
           @Title = ISNULL(Title, ''),
           @SheetId = Sheet_Id,
           @ActivityTypeId = Activity_Type_Id,@ActivityStatus=Activity_Status
		   ,@ActivityEndTime = Case when Activity_Status in (3,4) Then End_Time Else NULL End
           FROM Activities
           WHERE Activity_Id = @ActivityId

	Select @Sheet_Group_Id = Group_Id from sheets  where sheet_id = @SheetId
	SELECT @UserAccess = Access_Level from User_Security WHere User_Id =@UserId And ((Access_Level = 4 and Group_Id =1 ) OR (@Sheet_Group_Id= Group_Id AND Access_Level=4))
	
--Get Variables for this Activity
    Select @GraceTimeToEdit =( Select case when  value is null then 0 else cast(value as int) end from Site_PArameters Where Parm_Id = 614)
	INSERT INTO @Variables( varId,
                            VarOrder,
                            Title )
    SELECT varId,
           VarOrder,
           Title FROM dbo.fnActivities_GetVariablesForActivity(@ActivityId)
    SET @AliasColumnId = ISNULL((SELECT TOP 1 Value FROM dbo.Sheet_Display_Options AS SDO WHERE SDO.Display_Option_Id = 458
                                                                                                        AND SDO.Sheet_Id = @SheetId), 0);
    SET @VariableScrolling = CAST(ISNULL((SELECT Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId
                                                                                                AND Display_Option_Id = 449), 0) AS BIT)
    SELECT @IsInclusiveSpecs = value FROM Site_Parameters WHERE parm_id = 13
    SET @IsInclusiveSpecCalc = CAST(CASE
                                        WHEN ISNULL(@IsInclusiveSpecs, 1) = 1
                                        THEN 0
                                        ELSE 1
                                    END AS BIT)

    UPDATE a SET a.PUID = COALESCE(c.Master_Unit, c.PU_Id) ,
	a.Var_Desc = b.Var_Desc,
a.User_Defined1 = b.User_Defined1,
a.User_Defined2 = b.User_Defined2,
a.User_Defined3 = b.User_Defined3,
a.Eng_Units = b.Eng_Units,
a.Data_Type_Id = b.Data_Type_Id,
a.Var_Precision = b.Var_Precision,
a.SA_Id = b.SA_Id, a.Sampling_Interval = b.Sampling_Interval, a.esignatureLevel = b.Esignature_Level,
a.pu_desc = c.PU_Desc,a.pl_desc=pl.PL_Desc, a.pl_id = pl.PL_Id, a.dept_desc= dpt.Dept_Desc, a.dept_id = dpt.Dept_Id

	FROM @Variables a
                                                                JOIN Variables_Base b ON a.VarId = b.Var_Id
                                                                JOIN Prod_Units_Base c ON c.PU_Id = b.PU_Id
																JOIN Prod_Lines_Base pl  on pl.PL_Id = c.PL_Id
																join Departments_Base dpt on dpt.Dept_Id= pl.Dept_Id

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

    SELECT @PUID = MIN(PUId) FROM @Variables

    IF @SameProduct = 1
        BEGIN
            IF @ActivityTypeId IN(1, 4, 5) --Timed Event
                BEGIN
                    SELECT @ActivityEndTime = @KeyId
                END
                ELSE
                BEGIN
                    IF @ActivityTypeId = 2 --Production Event
                        BEGIN
                            SELECT @ActivityEndTime = e.Timestamp FROM Events AS e WHERE e.Event_Id = @KeyId1
                        END
                        ELSE
                        BEGIN
                            IF @ActivityTypeId = 3 --User Define Event
                                BEGIN
                                    SELECT @ActivityEndTime = e.End_Time FROM User_Defined_Events AS e WHERE e.UDE_Id = @KeyId1
                                END
                                ELSE
                                BEGIN
                                    SELECT Code = 'InvalidData',
                                           Error = 'Error - Activity Type not supported',
                                           ErrorType = 'NotSupported',
                                           PropertyName1 = 'ActivityId',
                                           PropertyName2 = '',
                                           PropertyName3 = '',
                                           PropertyName4 = '',
                                           PropertyValue1 = @ActivityId,
                                           PropertyValue2 = '',
                                           PropertyValue3 = '',
                                           PropertyValue4 = ''
                                END
                        END
                END

            SELECT @ActivityProductId = ps.Prod_Id
                   FROM production_starts AS ps
                   WHERE ps.PU_Id = @PUID
                         AND @ActivityEndTime >= Start_Time
                         AND (@ActivityEndTime < End_Time
                              OR End_Time IS NULL)

            INSERT INTO #ActivityData( ActivityId,
                                       ActivityDesc,
                                       ActivityDisplayTypeId,
                                       ActivityTypeId,
                                       KeyId1,
                                       KeyID,
                                       StartTime,
                                       GradeChanged,
                                       ProdId )
            SELECT TOP (@Size) a.Activity_Id,
                               a.Activity_Desc,
                               a.Display_Activity_Type_Id,
                               a.Activity_Type_Id,
                               a.KeyId1,
                               CASE @ActivityTypeId
                                   WHEN 2
                                   THEN e.TimeStamp
                                   WHEN 3
                                   THEN e2.End_Time
                                   ELSE a.KeyId
                               END AS TimeStamp,
                               a.Start_Time,
                               0,
                               @ActivityProductId
                   FROM Activities AS a
                        LEFT JOIN Events AS e ON e.Event_Id = a.KeyId1
                        LEFT JOIN User_Defined_Events AS e2 ON e2.UDE_Id = a.KeyId1
                        INNER JOIN Production_Starts AS ps ON ps.PU_Id = @PUID
                                                                      AND ps.PU_Id <> 0
                                                                      AND ps.Prod_Id = @ActivityProductId
                                                                      AND CASE @ActivityTypeId
                                                                              WHEN 2
                                                                              THEN e.TimeStamp
                                                                              WHEN 3
                                                                              THEN e2.End_Time
                                                                              ELSE a.KeyId
                                                                          END >= ps.Start_Time
                                                                      AND (CASE @ActivityTypeId
                                                                               WHEN 2
                                                                               THEN e.TimeStamp
                                                                               WHEN 3
                                                                               THEN e2.End_Time
                                                                               ELSE a.KeyId
                                                                           END < ps.End_Time
                                                                           OR ps.End_Time IS NULL)
                   WHERE a.Sheet_Id = @SheetId
                         AND (@DirectionBackward = 1 -- Backward: KeyID must be earlier
                              AND (@IsInclusive = 1
                                   AND TimeStamp <= @KeyId -- Inclusive: Can Equal StartTime
                                   OR @IsInclusive = 0
                                   AND TimeStamp < @KeyId) -- Exclusive: Must be Earlier than StartTime
                              OR @DirectionBackward = 0 -- Forward: KeyID must be later
                              AND (@IsInclusive = 1
                                   AND TimeStamp >= @KeyId -- Inclusive: Can Equal StartTime
                                   OR @IsInclusive = 0
                                   AND TimeStamp > @KeyId)) -- Exclusive: Must be Later than StartTime
                         AND ISNULL(Title, '') = @Title
                         AND Activity_Status IN(3, 4)
                   ORDER BY KeyId DESC
        END
        ELSE
        BEGIN
            IF @DirectionBackward = 1
                BEGIN
                    INSERT INTO #ActivityData( ActivityId,
                                               ActivityDesc,
                                               ActivityDisplayTypeId,
                                               ActivityTypeId,
                                               KeyId1,
                                               KeyID,
                                               StartTime,
                                               GradeChanged )
                    SELECT TOP (@Size) Activity_Id,
                                       Activity_Desc,
                                       Display_Activity_Type_Id,
                                       Activity_Type_Id,
                                       KeyId1,
                                       KeyID,
                                       Start_Time,
                                       0
                           FROM Activities
                           WHERE Sheet_Id = @SheetId
                                 AND (@DirectionBackward = 1 -- Backward: KeyID must be earlier
                                      AND (@IsInclusive = 1
                                           AND KeyId <= @KeyId -- Inclusive: Can Equal StartTime
                                           OR @IsInclusive = 0
                                           AND KeyId < @KeyId) -- Exclusive: Must be Earlier than StartTime
                                      OR @DirectionBackward = 0 -- Forward: KeyID must be later
                                      AND (@IsInclusive = 1
                                           AND KeyId >= @KeyId -- Inclusive: Can Equal StartTime
                                           OR @IsInclusive = 0
                                           AND KeyId > @KeyId)) -- Exclusive: Must be Later than StartTime
                                 AND ISNULL(Title, '') = @Title
                                 AND Activity_Status IN(3, 4)
                           ORDER BY KeyId DESC

                    IF @ActivityTypeId IN(1, 4, 5) --Timed Event
                        BEGIN
                            UPDATE #ActivityData SET EndTime = KeyID
                        END
                        ELSE
                        BEGIN
                            IF @ActivityTypeId = 2 --Production Event
                                BEGIN
                                    UPDATE a SET a.EndTime = e.Timestamp FROM #ActivityData a
                                                                              JOIN Events e ON e.Event_Id = a.KeyId1
                                END
                                ELSE
                                BEGIN
                                    IF @ActivityTypeId = 3 --User Define Event
                                        BEGIN
                                            UPDATE a SET a.EndTime = e.End_Time FROM #ActivityData a
                                                                                     JOIN User_Defined_Events e ON e.UDE_Id = a.KeyId1
                                        END
                                        ELSE
                                        BEGIN
                                            SELECT Code = 'InvalidData',
                                                   Error = 'Error - Activity Type not supported',
                                                   ErrorType = 'NotSupported',
                                                   PropertyName1 = 'ActivityId',
                                                   PropertyName2 = '',
                                                   PropertyName3 = '',
                                                   PropertyName4 = '',
                                                   PropertyValue1 = @ActivityId,
                                                   PropertyValue2 = '',
                                                   PropertyValue3 = '',
                                                   PropertyValue4 = ''
                                        END
                                END
                        END

                    SELECT @MaxTime = MAX(EndTime),
                           @MinTime = MIN(EndTime) FROM #ActivityData

                    SET @MaxTime = DATEADD(Minute, 10, @MaxTime)
                    SET @MinTime = DATEADD(Minute, -10, @MinTime)

                    UPDATE a SET a.OriginalProdId = E.Applied_Product,a.ProductStartTime = E.start_Time FROM #ActivityData a
                                                                           JOIN Events E ON E.PU_Id = @PUID
                                                                                                    AND a.StartTime <= E.TimeStamp
                                                                                                    AND a.EndTime >= E.Start_Time
                                                                                                    AND E.Applied_Product IS NOT NULL

                    UPDATE a
                      SET a.ProdId = Ps.Prod_Id, a.OriginalProdId = ISNULL(a.OriginalProdId, Ps.Prod_Id)
					  ,a.ProductStartTime = Ps.Start_Time
                          FROM #ActivityData a
                               JOIN Production_Starts Ps ON Ps.PU_Id = @PUID
                                                                    AND (Ps.Start_Time <= a.KeyID
                                                                         AND (Ps.End_Time > a.KeyID
                                                                              OR Ps.End_Time IS NULL))
                    UPDATE #ActivityData SET ProdId = 1 WHERE ProdId IS NULL
                    SET @MaxTime = DATEADD(Minute, -10, @MaxTime);
                    WITH S
                         AS (
                         SELECT *,
                                LEAD(ProdId) OVER(ORDER BY ActivityId DESC) PrevProdId FROM #ActivityData)
                         UPDATE s SET GradeChanged = CASE
                                                         WHEN ProdId <> PrevProdId
                                                         THEN 1
                                                         ELSE 0
                                                     END
                END
        END;
    --DECLARE @TempActivityData TABLE
	CREATE TABLE #TempActivityData(ActivityId            INT NULL,
                                    ActivityDesc          NVARCHAR(1000) NULL,
                                    ActivityDisplayTypeId INT NOT NULL,
                                    Title                 NVarchar(50) NULL,
                                    VarId                 INT NOT NULL,
                                    TestId                BIGINT NULL,
                                    VarDesc               nvarchar(50) NOT NULL,
                                    VariableName          nvarchar(255) NOT NULL,
                                    EngineeringUnits      nvarchar(15) NULL,
                                    DataTypeId            INT NOT NULL,
                                    DataType              nvarchar(50) NOT NULL,
                                    IsUserDefined         BIT NOT NULL,
                                    VarPrecision          tinyint NULL,
                                    VarOrder              INT NULL,
                                    Result                nvarchar(25) NULL,
                                    VariableScrolling     BIT NULL,
                                    IsInclusiveSpecCalc   BIT NULL,
                                    LocationId            INT NOT NULL,
                                    Location              nvarchar(50) NOT NULL,
                                    DepartmentId          INT NOT NULL,
                                    Department            nvarchar(50) NULL,
                                    LineId                INT NOT NULL,
                                    Line                  nvarchar(50) NULL,
                                    TestTime              DATETIME NULL,
                                    EventId               INT NULL,
                                    CommentId             INT NULL,
                                    ESignatureId          INT NULL,
                                    SecondUserId          INT NULL,
                                    SecondUser            NVARCHAR(255) NULL,
                                    Canceled              BIT NULL,
                                    ArrayId               INT NULL,
                                    IsLocked              TINYINT NULL,
                                    EntryOn               DATETIME NULL,
                                    EntryById             INT NULL,
                                    EntryBy               NVARCHAR(255) NULL,
                                    ProdId                INT NULL,
                                    ProdDesc              nvarchar(50) NOT NULL,
                                    StartTime             DATETIME NULL,
                                    GradeChanged          INT NULL,
                                    OriginalProdId        INT NULL
									,ProductStartTime     Datetime,
									SA_Id tinyint, Sampling_Interval int,
Test_Freq	int,
AS_Id	int,
L_Warning nvarchar(25),
L_Reject nvarchar(25),
L_Entry	nvarchar(25),
U_User	nvarchar(25),
Target	nvarchar(25),
L_User	nvarchar(25),
U_Entry	nvarchar(25),
U_Reject	nvarchar(25),
U_Warning	nvarchar(25),
Esignature_Level	int,
L_Control	nvarchar(25),
T_Control	nvarchar(25),
U_Control	nvarchar(25))



	--Select * from #ActivityData
	INSERT INTO #TempActivityData(ActivityId,ActivityDesc,ActivityDisplayTypeId,Title,VarId,TestId,VarDesc,VariableName,EngineeringUnits,DataTypeId,DataType,IsUserDefined,VarPrecision,VarOrder,Result,VariableScrolling,IsInclusiveSpecCalc,LocationId,Location,DepartmentId,Department,LineId,Line,TestTime,EventId,CommentId,ESignatureId,SecondUserId,SecondUser,Canceled,ArrayId,IsLocked,EntryOn,EntryById,EntryBy,ProdId,ProdDesc,StartTime,GradeChanged,OriginalProdId
	,ProductStartTime,Sampling_Interval	,AS_Id,Esignature_Level,SA_Id
	)
    SELECT  ActivityId = a.ActivityId,
           ActivityDesc = a.ActivityDesc,
           ActivityDisplayTypeId = ISNULL(a.ActivityDisplayTypeId, 0),
           Title = v.Title,
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
           VarPrecision = v.Var_Precision,
           VarOrder = v.VarOrder,
           t.Result,
           VariableScrolling = @VariableScrolling,
           IsInclusiveSpecCalc = @IsInclusiveSpecCalc,
           LocationId = v.PUId,
           Location = v.PU_Desc,
           DepartmentId = v.Dept_Id,
           Department = v.Dept_Desc,
           LineId = v.PL_Id,
           Line = v.PL_Desc,
           TestTime = a.KeyID,
           EventId = t.Event_Id,
           CommentId = t.Comment_Id,
           ESignatureId = t.Signature_Id,
           SecondUserId = t.Second_User_Id,
           SecondUser = u2.Username,
           Canceled = t.Canceled,
           ArrayId = t.Array_Id,
           IsLocked = t.Locked,
           EntryOn = t.Entry_On,
           EntryById = t.Entry_By,
           EntryBy = u.Username,
           ProdId = a.ProdId,
           ProdDesc = pb.Prod_Desc,
           StartTime = a.StartTime,
           GradeChanged = a.GradeChanged,
           OriginalProdId = a.OriginalProdId,
		   ProductStartTime  = a.ProductStartTime,
		   v.Sampling_Interval,
		   v.AS_Id,v.Esignature_Level,v.SA_Id
           FROM #ActivityData AS a
                CROSS APPLY @Variables AS v
                --JOIN Variables_Base AS v ON v.Var_Id = v1.varId
                JOIN Data_Type AS dt ON dt.Data_Type_Id = v.Data_Type_Id
                LEFT JOIN Tests AS t ON t.Var_Id = v.varId
                                                AND t.Result_On = a.KeyId
                LEFT JOIN Users_base AS u ON u.User_Id = t.Entry_By
                LEFT JOIN Users_base AS u2 ON u2.User_Id = t.Second_User_Id
                --JOIN Prod_Units_Base AS pu(nolock) ON pu.PU_Id = v.PUId
                --JOIN Prod_Lines_Base AS pl(nolock) ON pl.PL_Id = pu.PL_Id
                --JOIN Departments_Base AS dpt(nolock) ON dpt.Dept_Id = pl.Dept_Id
                JOIN Products_Base AS pb ON pb.Prod_Id = a.ProdId
                                                    Where  COALESCE(@ActivityTypeId, 0) > 0 -- valid activity was found

 IF 1=1
 BEgin
 ;WITH VarSpecs_Tmp As (Select * from Var_Specs where Var_Id in (Select varId from @Variables))
 UPDATE T
 SET
	T.U_Entry = s.U_Entry,
	T.U_Reject = s.U_Reject,
	T.L_Reject = s.L_Reject,
	T.U_Warning = s.U_Warning,
	T.L_Warning = s.L_Warning,
	T.U_User = s.U_User,
	T.L_User = s.L_User,
	T.U_Control = s.U_Control,
	T.L_Control = s.L_Control,
	T.Target = s.Target,
	T.T_Control = s.T_Control,
	T.Esignature_Level = Case when s.Esignature_Level IS NULL THEN T.Esignature_Level Else s.Esignature_Level End,
	T.Test_Freq = CASE WHEN T.Sampling_Interval IS NULL OR T.Sampling_Interval = 0 THEN s.Test_Freq ELSE T.Sampling_Interval END
 from
 #TempActivityData T
 LEFT JOIN VarSpecs_Tmp s ON T.VarId = s.Var_Id AND T.ProdId = s.Prod_Id
	AND
	(
		(
			ISNULL(T.SA_Id,1) <> 2 AND
			s.effective_date <= T.TestTime AND
			(
				(s.expiration_date > T.TestTime) OR (s.expiration_date IS NULL)
			)
		)
		OR
		(
			T.SA_Id = 2 AND
			s.effective_date <= T.ProductStartTime AND
			(
				(s.expiration_date > T.ProductStartTime) OR (s.expiration_date IS NULL)
			)
		)
	)
 ENd

 UPDATE T
      SET T.StartTime = T.StartTime at time zone @DBZone at time zone 'UTC' ,
	  T.TestTime = T.TestTime at time zone @DBZone at time zone 'UTC',
	  T.EntryOn = T.EntryOn at time zone @DBZone at time zone 'UTC'
          FROM #TempActivityData T

    SELECT *,case when  @UserAccess = 4 Then 1 Else Case when Dateadd(minute,@GraceTimeToEdit ,@ActivityEndTime) > Getdate() AND  @ActivityStatus in (3,4) then 1 else 0 end end IsSheetEditable FROM #TempActivityData  ORDER BY TestTime DESC, ActivityId DESC,VarOrder
END
