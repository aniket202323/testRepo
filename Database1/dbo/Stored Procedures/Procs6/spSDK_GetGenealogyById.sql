CREATE PROCEDURE dbo.spSDK_GetGenealogyById
 	 @ComponentId 	  	 INT
AS
SELECT 	 GenealogyLinkId = ec.Component_Id,
 	  	  	 ParentLineName = pl1.pl_desc,
 	  	  	 ParentUnitName = pu1.pu_desc, 
 	  	  	 ParentEventName = e1.Event_Num, 
 	  	  	 ParentEventType = es1.Event_Subtype_Desc, 
 	  	  	 ChildLineName = pl2.pl_desc,
 	  	  	 ChildUnitName = pu2.pu_desc, 
 	  	  	 ChildEventName = e2.Event_Num, 
 	  	  	 ChildEventType = es2.Event_Subtype_Desc,
 	  	  	 DimensionX = ec.Dimension_X, 
 	  	  	 DimensionY = ec.Dimension_Y,
 	  	  	 DimensionZ = ec.Dimension_Z,
 	  	  	 DimensionA = ec.Dimension_A,
 	  	  	 LevelNumber = 0,
 	  	  	 ExtendedInfo = ec.Extended_Info, 	 
 	  	  	 StartCoordinateX = ec.Start_Coordinate_X,
 	  	  	 StartCoordinateY = ec.Start_Coordinate_Y,
 	  	  	 StartCoordinateZ = ec.Start_Coordinate_Z,
 	  	  	 StartCoordinateA = ec.Start_Coordinate_A,
 	  	  	 StartTime = ec.Start_Time,
 	  	  	 EndTime = ec.Timestamp,
 	  	  	 ParentComponentId = ec.Parent_Component_Id,
            SignatureId = ec.Signature_Id
 	 FROM 	 Event_Components ec
 	 JOIN  	 Events e1  	  	  	  	  	 ON  	 e1.Event_id = ec.Source_Event_id 
 	 JOIN  	 Event_Configuration ec1 ON  	 e1.PU_Id = ec1.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	 AND 	 ec1.ET_Id = 1
 	 JOIN 	 Event_SubTypes es1 	  	 ON  	 ec1.Event_Subtype_Id = es1.Event_Subtype_Id 
 	 JOIN 	 Prod_Units pu1  	  	  	 ON  	 pu1.PU_id = e1.PU_Id
 	 JOIN  	 Prod_Lines pl1  	  	  	 ON  	 pl1.pl_id = pu1.pl_id 
 	 JOIN 	 Events e2  	  	  	  	  	 ON  	 e2.Event_id = ec.Event_id
 	 JOIN 	 Event_Configuration ec2 ON  	 e2.PU_Id = ec2.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	 AND 	 ec2.ET_Id = 1
 	 JOIN 	 Event_SubTypes es2 	  	 ON 	  	 ec2.Event_Subtype_Id = es2.Event_Subtype_Id
 	 JOIN 	 Prod_Units pu2  	  	  	 ON  	 pu2.PU_id = e2.PU_Id 
 	 JOIN  	 Prod_Lines pl2  	  	  	 ON  	 pl2.pl_id = pu2.pl_id
 	 WHERE ec.Component_Id = @ComponentId
