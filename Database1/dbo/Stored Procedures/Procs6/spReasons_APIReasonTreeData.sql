CREATE PROCEDURE [dbo].[spReasons_APIReasonTreeData]
@PUId                nvarchar(max), 
@TreeType 	  	  	  	 Int = 1,
@MaxLevel 	  	  	  	 Int = 1,
@EventType               Int = 2  
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/

    IF @PUId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @PUId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @PUId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
DECLARE @reasons TABLE (
                    Tree_Name_Id int,
                    Event_Reason_Tree_Data_Id int,
                    Parent_Event_R_Tree_Data_Id int,
                    Event_Reason_Level int,
                    Event_Reason_Id int,
                    Event_Reason_Name nvarchar(1000),
                    Level1_Id int,
                    Level2_Id int,
                    Level3_Id int,
                    Level4_Id int,
                    ERC_Id int,
                    ERCD_Id int,
                                                                                Comment_Required bit
)
       IF (@TreeType IN (1,2))
       BEGIN
                    Insert Into  @reasons  (
                    Tree_Name_Id ,
                    Event_Reason_Tree_Data_Id ,
                    Parent_Event_R_Tree_Data_Id ,
                    Event_Reason_Level ,
                    Event_Reason_Id ,
                    Event_Reason_Name ,
                    Level1_Id ,
                    Level2_Id ,
                    Level3_Id ,
                    Level4_Id ,
                    ERC_Id ,
                    ERCD_Id,
                                                                                Comment_Required)
              SELECT ertd.Tree_Name_Id,ertd.Event_Reason_Tree_Data_Id,ertd.Parent_Event_R_Tree_Data_Id,
                     ertd.Event_Reason_Level, ertd.Event_Reason_Id,er.Event_Reason_Name,-- AS reasonName,  
                     ertd.Level1_Id,ertd.Level2_Id,ertd.Level3_Id, ertd.Level4_Id,min(ercd.ERC_Id), min(ercd.ERCD_Id),
                                                                                er.Comment_Required
                     FROM prod_units pu
                     JOIN Prod_Events pe ON ( pe.PU_Id = pu.PU_Id AND pe.Event_Type = @EventType)
                                    JOIN event_reason_tree_data ertd ON ertd.Tree_Name_Id = 
                                    CASE WHEN @TreeType = 1 THEN   pe.Name_Id  
                                                ELSE
                                                       pe.Action_Tree_Id 
                                                END
                      JOIN event_reasons er ON (ertd.event_reason_id = er.event_reason_id)  
                      LEFT JOIN Event_Reason_Category_Data ercd ON (ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id) 
                      LEFT JOIN Event_Reason_Catagories erc ON (erc.ERC_Id = ercd.ERC_Id) 
                     WHERE pu.pu_id = @PUId AND 
					 (
                      (@EventType = 3 AND pu.Waste_Event_Association > 0 AND pu.Waste_Event_Association IS NOT NULL) 
				   OR
				   (@EventType = 2 AND pu.timed_event_association > 0 AND  pu.timed_event_association IS NOT NULL)
					 ) AND
                     ertd.Event_Reason_Level <= @MaxLevel
                     GROUP BY Tree_Name_Id,ertd.Event_Reason_Tree_Data_Id ,
                    Parent_Event_R_Tree_Data_Id ,
                    Event_Reason_Level ,
                    ertd.Event_Reason_Id ,
                    er.Event_Reason_Name ,
                    ertd.Level1_Id ,
                    ertd.Level2_Id ,
                    ertd.Level3_Id ,
                    ertd.Level4_Id,
                                                                                er.Comment_Required
       END
       ELSE IF @TreeType = 3
       BEGIN
              INSERT INTO  @reasons  (
                    Tree_Name_Id ,
                    Event_Reason_Tree_Data_Id ,
                    Parent_Event_R_Tree_Data_Id ,
                    Event_Reason_Level ,
                    Event_Reason_Id ,
                    Event_Reason_Name ,
                    Level1_Id ,
                    Level2_Id ,
                    Level3_Id ,
                    Level4_Id ,
                    ERC_Id ,
                    ERCD_Id,
                                                                                Comment_Required
)
              SELECT ertd.Tree_Name_Id,ertd.Event_Reason_Tree_Data_Id,ertd.Parent_Event_R_Tree_Data_Id,
                         ertd.Event_Reason_Level, ertd.Event_Reason_Id,er.Event_Reason_Name,-- AS reasonName,  
                         ertd.Level1_Id,ertd.Level2_Id,ertd.Level3_Id, ertd.Level4_Id,min(ercd.ERC_Id), min(ercd.ERCD_Id), 
                                                                                                 er.Comment_Required
                         FROM prod_units pu
                         JOIN event_reason_tree_data ertd ON ( ertd.Tree_Name_Id = pu.Non_Productive_Reason_Tree )
                         JOIN event_reasons er ON (ertd.event_reason_id = er.event_reason_id) 
                         LEFT JOIN Event_Reason_Category_Data ercd ON (ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id) 
                         LEFT JOIN Event_Reason_Catagories erc ON (erc.ERC_Id = ercd.ERC_Id) 
                         WHERE pu.pu_id = @PUId AND 
                         pu.timed_event_association > 0 AND  pu.timed_event_association IS NOT NULL AND
                         ertd.Event_Reason_Level <= @MaxLevel
                         GROUP BY Tree_Name_Id,ertd.Event_Reason_Tree_Data_Id ,
                    Parent_Event_R_Tree_Data_Id ,
                    Event_Reason_Level ,
                    ertd.Event_Reason_Id ,
                    er.Event_Reason_Name ,
                    ertd.Level1_Id ,
                    ertd.Level2_Id ,
                    ertd.Level3_Id ,
                    ertd.Level4_Id     ,er.Comment_Required 
       END
SELECT r.Tree_Name_Id ,
       r.Event_Reason_Tree_Data_Id ,
       r.Parent_Event_R_Tree_Data_Id ,
       r.Event_Reason_Level ,
       r.Event_Reason_Id ,
       r.Event_Reason_Name AS reasonName ,
       r.Level1_Id ,
       r.Level2_Id ,
       r.Level3_Id ,
       r.Level4_Id,r.ERC_Id as categoryId,erc.ERC_Desc AS categoryName ,r.ERCD_Id AS categoryNodeId 
 	    ,r.Comment_Required AS commentRequired
       FROM @reasons r   
       LEFT JOIN Event_Reason_Catagories erc ON (r.ERC_Id = erc.ERC_Id) 
       ORDER BY r.Event_Reason_Level
