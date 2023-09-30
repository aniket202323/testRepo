CREATE procedure [dbo].[spSDK_LoadSDKObjectConfig]
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
 	  	  	  	 ct.ClauseName, cd.ClauseGroupNumber, cd.ClauseData, props.Calculation, obj.NLSPromptId as ObjectNLSPromptId, props.NLSPromptId as PropNLSPromptId
from SDK_Objects obj 
left outer join SDK_Object_Properties props on (obj.ObjectId = props.ObjectId) and (props.SDKVersion = '5.0')
left join @T1 on LocalNames = props.QueryLocationName + '_Local'
left join @T2 on GlobalNames = props.QueryLocationName + '_Global'
left outer join SDK_Objects objlookup on objlookup.ObjectId = props.StringToIdLookupObjectId
left outer join SDK_Clause_Data cd on (cd.ObjectId = props.ObjectId) and (cd.SDKVersion = '5.0')
left outer join SDK_Clause_Types ct on ct.ClauseId = cd.ClauseId
where obj.SDKVersion = '5.0'
order by obj.ObjectName, props.PropertyName, props.StingToIdEvaluationOrder, cd.ClauseGroupNumber, ct.ClauseName
