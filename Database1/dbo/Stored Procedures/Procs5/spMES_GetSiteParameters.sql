
CREATE PROCEDURE dbo.spMES_GetSiteParameters
    @ParamId  INT = NULL
AS

/*---------------------------------------------------------------------------------------------------------------------
    This stored procedure returns a site parameter value
  
    Date         Ver/Build   Author              Story/Defect        Remarks
    22-Oct-2020	 001         Suman Kotagiri		 DE141364            Initial Development
	28-Oct-2020  002         Evgeniy Kim	     DE141364            Updated to return value by @ParamId

---------------------------------------------------------------------------------------------------------------------*/

SELECT	Parm_Id, 
		[Value]
FROM	Site_Parameters WITH(NOLOCK)
WHERE	Parm_Id = @ParamId;

