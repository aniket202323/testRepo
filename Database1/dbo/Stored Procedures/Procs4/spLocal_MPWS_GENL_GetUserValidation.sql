 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetUserValidation]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PWFunction		VARCHAR(50),
	@PWAction		VARCHAR(50),
	@Type			VARCHAR(20),	--valid are "Button","ESig","VerifierESig"
	@UserId			INT = NULL,
	@UserName		VARCHAR(50) = NULL
--WITH ENCRYPTION	
AS	
 
-------------------------------------------------------------------------
 
-- Test vars
--DECLARE 
--	@ErrorCode		INT				,
--	@ErrorMessage	VARCHAR(500)	,
--	@PWFunction		VARCHAR(50) = 'Dispense',
--	@PWAction		VARCHAR(50) = 'Dispense',
--	@Type			VARCHAR(10) = 'VerifierESig',	--valid are "Button","ESig","VerifierESig"
--	@UserId			INT = 986,--1022, 
--	@UserName		VARCHAR(50) = NULL
 
SET NOCOUNT ON

/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_GetUserValidation
 
	Get Preweigh button control and eSig Configuration Info for a UserId based on Function and Action. Returns @ErrorCode = -1 if the UserId has no allowed Actions.
	
	Date			Version	Build	Author  
	23-Aug-2017		001		001		Susan Lee (GE Digital)	Initial release
	06-Oct-2017		001		001		Susan Lee and Fran Osorno updated the code to standard
	10-Nov-2017     002		001		Susan Lee (GE Digital)	Fixed Verifier group role check
	 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_GetUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 
'Inventory', 'AdjustRMC','Button', null, 'lee.s.3'
--exec dbo.spLocal_MPWS_GENL_GetUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Dispense','Dispense', ,'ESig', 1022, null
select @ErrorCode, @ErrorMessage
 
------------------------------------------------------------------------------- */
Declare @ErrCode		 INT,
		@ErrMsg			 VARCHAR(500),
        @SecurityGroup   VARCHAR(50),
        @TableField      VARCHAR(50)
 
Create table #OutputTable
(
Usr_Id int,
UserName varchar(50),
PWAction varchar(50),
ButtonGroup varchar(50),
ESigGroup varchar(50),
VerifierEsigGroup varchar(50),
ErrCode int,
ErrMessage varchar(500)
)
 
SELECT
       @SecurityGroup       = 'PreWeigh',
       @TableField          = 'PreWeighGroup'
 
CREATE TABLE #Data (
       ID                   INT IDENTITY,
       GroupID				INT,
	   UserRole				VARCHAR(50),
       RoleAccessLevel		INT,
	   UserAccessLevel		INT,
       GroupCrossRef        VARCHAR(50)
       )
 
CREATE TABLE #DomainGroups (
		ID			INT IDENTITY,
		GroupName	VARCHAR(50)
		)
 
INSERT INTO #DomainGroups (GroupName) 
VALUES	('Manufacturing Leader'),
		('MDATA'),
		('Operator')
 
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';
	
	set @ErrCode = @ErrorCode;
	set @ErrMsg = @ErrorMessage;
 
IF ISNULL(@UserName, '') = '' AND ISNULL(@UserId, 0) = 0
BEGIN
 
	SELECT
		@ErrorCode		= -2,
		@ErrorMessage	= 'UserName or UserId must be supplied';
		
	set @ErrCode = @ErrorCode;
	set @ErrMsg = @ErrorMessage;
 
END;
 
IF NOT EXISTS (SELECT PWFunction FROM dbo.Local_MPWS_GENL_ESigActionConfig (NOLOCK) WHERE PWFunction = @PWFunction)
BEGIN
 
	SELECT
		@ErrorCode		= -3,
		@ErrorMessage	= 'PWFunction ' + @PWFunction + ' does not exist';
		
	set @ErrCode = @ErrorCode;
	set @ErrMsg = @ErrorMessage;
 
END;
 
IF NOT EXISTS (SELECT PWAction FROM dbo.Local_MPWS_GENL_ESigActionConfig (NOLOCK) WHERE PWFunction = @PWFunction AND PWAction = @PWAction)
BEGIN
 
	SELECT
		@ErrorCode		= -4,
		@ErrorMessage	= 'PWAction ' + @PWAction + ' does not exist for PWFunction ' + @PWFunction;
 
    set @ErrCode = @ErrorCode;
	set @ErrMsg = @ErrorMessage;
END;
 
IF @ErrorCode > 0
BEGIN
INSERT INTO #Data(RoleAccessLevel,GroupCrossRef,GroupID, UserRole )
SELECT us.access_level,tfv.value,sg.Group_Id,u.Username
       FROM dbo.user_security us (NOLOCK)
              JOIN dbo.users_base u (NOLOCK) ON u.user_id = us.user_id
              JOIN dbo.Security_Groups sg (NOLOCK) ON sg.group_id = us.group_id
              LEFT JOIN dbo.Table_Fields_Values tfv (NOLOCK) ON tfv.keyid = u.user_id
                     LEFT JOIN dbo.table_fields tf (NOLOCK) ON tf.table_field_id = tfv.table_field_id
			   JOIN #DomainGroups dg (NOLOCK)  ON dg.GroupName = u.username
       WHERE 
              sg.group_desc = @SecurityGroup AND
                     tf.Table_Field_Desc = @TableField
 
UPDATE d
      SET 	UserAccessLevel = us.access_level	
       FROM dbo.User_Security us (NOLOCK) 
              JOIN dbo.users_base u (NOLOCK) ON u.user_id = us.user_id
              JOIN dbo.Security_Groups sg (NOLOCK) ON sg.Group_Id = us.Group_Id
              JOIN #Data d ON d.GroupID = sg.Group_Id
       WHERE (u.username = @Username AND @UserName IS NOT NULL) OR (u.user_id = @UserId AND @UserId IS NOT NULL)
		AND us.Access_Level >= d.RoleAccessLevel
 
Insert into #OutputTable(Usr_Id,UserName,PWAction,ButtonGroup,ESigGroup,VerifierEsigGroup)
(
	SELECT
		u.[User_Id], 
		u.UserName,
		esac.PWAction,
		esac.ValidUserGroup,
		esac.ESigGroup,
		esac.ESigVerifierGroup
	FROM dbo.Local_MPWS_GENL_ESigActionConfig esac (NOLOCK)
	JOIN dbo.Users_Base u (NOLOCK) ON (u.user_id = @UserId AND @UserId IS NOT NULL) OR (u.username = @UserName AND @UserName IS NOT NULL)
	WHERE esac.PWFunction = @PWFunction AND esac.PWAction = @PWAction
)	
	
END;
 
IF (	SELECT COUNT(*) 
		FROM #OutputTable o (NOLOCK)
		JOIN #Data d (NOLOCK) ON 
			
			(@Type='Button' AND o.ButtonGroup = d.GroupCrossRef and d.UserAccessLevel >= RoleAccessLevel)
		  OR(@Type='ESig' AND o.ESigGroup = d.GroupCrossRef and d.UserAccessLevel >= RoleAccessLevel)
		  OR(@Type='VerifierESig' AND o.VerifierEsigGroup = d.GroupCrossRef and d.UserAccessLevel >= RoleAccessLevel)
	 ) = 0
 
BEGIN
 
	SELECT
		@ErrorCode		= -1,
		@ErrorMessage	= 'User not valid for ' + @PWAction + ' for ' + @Type;
	
    set @ErrCode = @ErrorCode;
	set @ErrMsg = @ErrorMessage;
	
	Insert into #OutputTable (ErrCode, ErrMessage)
	values (@ErrCode,@ErrMsg )
 
END;
 
Update #OutputTable
set ErrCode = @ErrCode , ErrMessage = @ErrMsg
where Usr_Id is not null
 
SELECT	* 
FROM	#OutputTable (NOLOCK)
WHERE	Usr_Id IS NOT NULL 
 
CleanUp:
DROP TABLE #OutputTable
DROP TABLE #Data
DROP TABLE #DomainGroups
 
