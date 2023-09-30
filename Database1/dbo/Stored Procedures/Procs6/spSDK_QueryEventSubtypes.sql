Create Procedure dbo.spSDK_QueryEventSubtypes
 	 @EventSubtypeId 	  	  	 INT 	  	  	  	 = NULL,
 	 @EventTypeMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @EventSubTypeMask 	  	  	 nvarchar(50) 	 = NULL
AS
SELECT 	 @EventTypeMask  	 = REPLACE(REPLACE(REPLACE(COALESCE(@EventTypeMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 @EventSubtypeMask 	 = REPLACE(REPLACE(REPLACE(COALESCE(@EventSubtypeMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 EventSubTypeId 	  	  	 = es.Event_Subtype_Id,
 	  	  	 EventTypeName 	  	  	 = et.ET_Desc,
 	  	  	 EventSubtypeName 	  	 = es.Event_Subtype_Desc,
 	  	  	 EventMask 	  	  	  	 = es.Event_Mask,
 	  	  	 DimensionXName 	  	  	 = es.Dimension_X_Name,
 	  	  	 DimensionXEngUnits 	 = es.Dimension_X_Eng_Units,
 	  	  	 DimensionYEnabled 	  	 = es.Dimension_Y_Enabled,
 	  	  	 DimensionYName 	  	  	 = es.Dimension_Y_Name,
 	  	  	 DimensionYEngUnits 	 = es.Dimension_Y_Eng_Units,
 	  	  	 DimensionZEnabled 	  	 = es.Dimension_Z_Enabled,
 	  	  	 DimensionZName 	  	  	 = es.Dimension_Z_Name,
 	  	  	 DimensionZEngUnits 	 = es.Dimension_Z_Eng_Units,
 	  	  	 DimensionAEnabled 	  	 = es.Dimension_A_Enabled,
 	  	  	 DimensionAName 	  	  	 = es.Dimension_A_Name,
 	  	  	 DimensionAEngUnits 	 = es.Dimension_A_Eng_Units,
 	  	  	 CauseRequired 	  	  	 = es.Cause_Required,
 	  	  	 ActionRequired 	  	  	 = es.Action_Required,
 	  	  	 AckRequired 	  	  	  	 = es.Ack_Required,
 	  	  	 CauseTreeName 	  	  	 = crt.Tree_Name,
 	  	  	 DefaultCause1 	  	  	 = es.Default_Cause1,
 	  	  	 DefaultCause2 	  	  	 = es.Default_Cause2,
 	  	  	 DefaultCause3 	  	  	 = es.Default_Cause3,
 	  	  	 DefaultCause4 	  	  	 = es.Default_Cause4,
 	  	  	 ActionTreeName 	  	  	 = art.Tree_Name,
 	  	  	 DefaultAction1 	  	  	 = es.Default_Action1,
 	  	  	 DefaultAction2 	  	  	 = es.Default_Action2,
 	  	  	 DefaultAction3 	  	  	 = es.Default_Action3,
 	  	  	 DefaultAction4 	  	  	 = es.Default_Action4,
 	  	  	 ExtendedInfo 	  	  	 = es.Extended_Info,
 	  	  	 CommentId 	  	  	  	 = es.Comment_Id,
                        ESignatureLevel                 = Coalesce(ESignature_Level,0)
 	 FROM 	  	  	 Event_Types et
 	 INNER 	 JOIN 	 Event_Subtypes es 	  	  	 ON 	 es.ET_Id = et.ET_Id
 	 LEFT 	 JOIN 	 Event_Reason_Tree crt 	 ON 	 crt.Tree_Name_Id = es.Cause_Tree_Id
 	 LEFT 	 JOIN 	 Event_Reason_Tree art 	 ON 	 art.Tree_Name_Id = es.Action_Tree_Id 
 	 WHERE 	 et.ET_Desc LIKE @EventTypeMask
 	 AND 	 es.Event_Subtype_Desc LIKE @EventSubtypeMask
 	 AND 	 (es.Event_Subtype_Id = @EventSubtypeId OR @EventSubtypeId IS NULL)
 	 ORDER BY et.ET_Desc, es.Event_Subtype_Desc
