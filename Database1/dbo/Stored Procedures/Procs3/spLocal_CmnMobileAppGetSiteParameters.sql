CREATE  PROCEDURE [dbo].spLocal_CmnMobileAppGetSiteParameters
@HostName                   Varchar_Desc=NULL,
@ParameterCategoryId             int=NULL,
@ParameterCategoryName           Varchar_Desc=NULL,
@ParameterId                int=NULL,
@ParameterName              Varchar_Desc=NULL

AS
SET NOCOUNT ON

DECLARE
@catId INT=NULL

SET @catId = (SELECT Parameter_Category_Id FROM dbo.[Parameter_Categories] WHERE [Parameter_Category_Desc] = @ParameterCategoryName)

SELECT
    sp.HostName,
    sp.Parm_Id,
    sp.value,
    p.*
FROM
    dbo.site_parameters sp
INNER JOIN
    Parameters p WITH(NOLOCK)
ON sp.Parm_Id = p.Parm_Id
WHERE
    ((ISNULL(@HostName,'')>'' AND sp.HostName = @HostName) OR ISNULL(@HostName,'')='' ) AND
    ((@ParameterCategoryId IS NOT NULL AND p.Parameter_Category_Id = @ParameterCategoryId) OR @ParameterCategoryId IS NULL) AND
    ((ISNULL(@ParameterCategoryName,'')>'' AND p.Parameter_Category_Id = @catId) OR ISNULL(@ParameterCategoryName,'')='') AND
    ((@ParameterId IS NOT NULL AND p.parm_id = @ParameterId) OR @ParameterId IS NULL ) AND
    ((ISNULL(@ParameterName,'')>'' AND p.Parm_Name = @ParameterName) OR ISNULL(@ParameterName,'')='')

SET NOCOUNT OFF
RETURN