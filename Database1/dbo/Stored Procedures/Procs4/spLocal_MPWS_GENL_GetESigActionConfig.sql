 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetESigActionConfig]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PWFunction		VARCHAR(250),
	@PWAction		VARCHAR(250)
	
AS	
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_GetESigActionConfig
 
	Get Preweigh ESig Configuration Info based on Function and Action
	
	Date			Version	Build	Author  
	01-Jul-2016		001		001		Jim Cameron (GEIP)		Initial development	
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
 
--exec dbo.spLocal_MPWS_GENL_GetESigActionConfig @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Inventory', 'ReturnInventory'
--select @ErrorCode, @ErrorMessage
 
exec dbo.spLocal_MPWS_GENL_GetESigActionConfig @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Inventory', 'All'
select @ErrorCode, @ErrorMessage
 
------------------------------------------------------------------------------- */
 
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';
	
SELECT
	esac.Id,
	esac.PWAction,
	esac.PWFunction,
	esac.ValidUserGroup,
	CASE WHEN esac.ESigEnabled = 1 THEN 'True' ELSE 'False' END EsigEnabled,
	CASE WHEN esac.ESigVerifierEnabled = 1 THEN 'True' ELSE 'False' END ESigVerifierEnabled,
	esac.ESigStatement,
	esac.ESigGroup,
	esac.ESigVerifierGroup
FROM dbo.Local_MPWS_GENL_ESigActionConfig esac
WHERE (
		@PWAction = 'All'
		OR 
		esac.PWAction IN (	SELECT
								x.y.value('.', 'varchar(50)') NotificationArea
							FROM (SELECT CAST('<p>' + REPLACE(@PWAction, ',', '</p><p>') + '</p>' AS XML) q) p
								CROSS APPLY q.nodes('/p/text()') x(y) )
	)
	AND
	(
		@PWFunction = 'All'
		OR 
		esac.PWFunction IN (SELECT
								x.y.value('.', 'varchar(50)') NotificationArea
							FROM (SELECT CAST('<p>' + REPLACE(@PWFunction, ',', '</p><p>') + '</p>' AS XML) q) p
								CROSS APPLY q.nodes('/p/text()') x(y) )
	)
 
