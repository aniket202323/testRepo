CREATE procedure [dbo].[spSDK_LoadSDKObjectConfig60]
AS
DECLARE @UserId INT
DECLARE @T1 TABLE (LocalNames Varchar(500) COLLATE DATABASE_DEFAULT)
DECLARE @T2 TABLE (GlobalNames Varchar(500) COLLATE DATABASE_DEFAULT)
INSERT INTO @T1(LocalNames)
 	 SELECT  so.name + '.' + sc.name 
 	  	 FROM dbo.syscolumns sc
 	  	 Join dbo.sysobjects so on so.id = sc.id and so.type = 'U'
 	  	 WHERE sc.name Like '%_local' 
INSERT INTO @T2(GlobalNames)
 	 SELECT  so.name + '.' + sc.name 
 	  	 FROM dbo.syscolumns sc
 	  	 Join dbo.sysobjects so on so.id = sc.id and so.type = 'U'
 	  	 WHERE sc.name Like '%_Global' 
select  obj.ObjectName,props.PropertyName, 
 	  	  	  	 props.IsKey,  
 	  	  	  	 COALESCE(props.LinkedPropertyName,'') as LinkedPropertyName, 
 	  	  	  	 COALESCE(objlookup.ObjectName,'') as StringToIdLookupObjectName,
 	  	  	  	 props.DefaultValue, 
 	  	  	  	 LocalNames as LocalizedName,
 	  	  	  	 GlobalNames as GlobalizedName,
 	  	  	  	 obj.MainDbTable, obj.Namespace,
 	  	  	  	 COALESCE(props.ForceDefaultOnInsertUpdate,0) as ForceDefaultValueOnAddAndUpdate,
 	  	  	  	 props.QueryLocationName, props.PropertyDescription, props.IsExtraLookupProperty, props.IsCustomLookupProperty,
 	  	  	  	 COALESCE(obj.DefaultQueryRowCount,'') as DefaultQueryRowCount, COALESCE(props.SqlDataTypeName,'') as SqlDataTypeName,
 	  	  	  	 props.IsAddable, props.IsUpdatable, COALESCE(props.StingToIdEvaluationOrder,'0') as StingToIdEvaluationOrder, props.DefaultIsSelectedForQuery, 	 props.DefaultOrderByForQuery,
 	  	  	  	 ct.ClauseName, cd.ClauseGroupNumber, cd.ClauseData, props.Calculation, 
 	  	  	  	 COALESCE(obj.CanDoWD,0) as 	 CanDoWD,
 	  	  	  	 COALESCE(obj.WDSPName,'') as 	 WDSPName,
 	  	  	  	 COALESCE(obj.WDSPSuccessCodes,'') as 	 WDSPSuccessCodes,
 	  	  	  	 COALESCE(obj.WDSPNoActionCodes,'') as 	 WDSPNoActionCodes,
 	  	  	  	 COALESCE(obj.WDSPLazyCodes,'') as 	 WDSPLazyCodes,
 	  	  	  	 COALESCE(obj.WDSendsMsg,1) as 	 WDSendsMsg,
 	  	  	  	 COALESCE(props.IsWDDBParam,0) as IsWDDBParam,
 	  	  	  	 COALESCE(props.IsReqWDDBParam,0) as IsReqWDDBParam,
 	  	  	  	 COALESCE(props.WDParamDirection,'') as WDParamDirection,
 	  	  	  	 COALESCE(props.WDSPParamName,'') as WDSPParamName,
 	  	  	  	 COALESCE(Tables.TableId,0) as MainDbTableId,
 	  	  	  	 COALESCE(Tables.Allow_User_Defined_Property,0) as AllowUserDefinedProperty,
 	  	  	  	 COALESCE(props.AccessLevelItemNum,0) as AccessLevelItemNum,
 	  	  	  	 COALESCE(obj.CanDoDEI,0) as 	 CanDoDEI,
 	  	  	  	 COALESCE(obj.DEISPName,'') as 	 DEISPName,
 	  	  	  	 COALESCE(props.IsDEIParam,0) as IsDEIParam,
 	  	  	  	 COALESCE(props.DEIParamName,'') as DEIParamName,
 	  	  	  	 COALESCE(props.DEIChangeParamName,'') as DEIChangeParamName,
 	  	  	  	 COALESCE(obj.CanDoESigInfo,0) as 	 CanDoESigInfo,
 	  	  	  	 COALESCE(obj.ESigInfoSPName,'') as 	 ESigInfoSPName,
 	  	  	  	 COALESCE(props.IsESigInfoParam,0) as IsESigInfoParam,
 	  	  	  	 COALESCE(props.ESigInfoParamName,'') as ESigInfoParamName,
 	  	  	  	 COALESCE(props.IsESigProperty,0) as IsESigProperty
from SDK_Objects obj 
left outer join SDK_Object_Properties props on (obj.ObjectId = props.ObjectId) and (props.sdkversion = '6.0')
left join @T1 on LocalNames = props.QueryLocationName + '_Local'
left join @T2 on GlobalNames = props.QueryLocationName + '_Global'
left outer join SDK_Objects objlookup on objlookup.ObjectId = props.StringToIdLookupObjectId
left outer join SDK_Clause_Data cd on (cd.ObjectId = props.ObjectId) and (cd.sdkversion = '6.0')
left outer join SDK_Clause_Types ct on ct.ClauseId = cd.ClauseId
left join Tables on Tables.TableName = obj.MainDbTable
where obj.sdkversion = '6.0'
order by obj.ObjectName, props.PropertyName, props.StingToIdEvaluationOrder, cd.ClauseGroupNumber, ct.ClauseName
