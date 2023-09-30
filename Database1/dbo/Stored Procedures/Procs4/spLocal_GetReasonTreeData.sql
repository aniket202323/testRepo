 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetReasonTreeData  
Author:   Fran Osorno  
Date Created:  08/03/04  
  
Description:  
=========  
This  get all of the reason tree data for the site.  
 This sp is used in the reson tree function created in MS Access  
  
Change Date  Who What  
=========== ==== =====  
08/03/04  FGO Created  
*/  
CREATE PROCEDURE dbo.spLocal_GetReasonTreeData  
AS  
  
SET NOCOUNT ON  
  
SELECT   tree_name AS [Reason Tree Name],  
 [ReasonLevel1] = CASE  
  WHEN er.event_reason_name IS NOT NULL  
   THEN er.event_reason_name  
  ELSE 'Not Used'  
  END,  
 [ReasonLevel2] = CASE  
  WHEN er1.event_reason_name IS NOT NULL  
   THEN er1.event_reason_name  
  ELSE 'Not Used'  
  END,  
 [ReasonLevel3] = CASE  
  WHEN er2.event_reason_name IS NOT NULL  
   THEN er2.event_reason_name  
  ELSE 'Not Used'  
  END,  
 [ReasonLevel4] = CASE  
  WHEN er3.event_reason_name IS NOT NULL  
   THEN er3.event_reason_name  
  ELSE 'Not Used'  
  END,  
 [Reason Category] = CASE   
  WHEN ertd.parent_event_r_tree_data_id IS NOT NULL   
   THEN erc.erc_desc  
  WHEN ertd1.parent_event_r_tree_data_id IS NOT NULL   
    AND ertd2.parent_event_r_tree_data_id IS  NULL   
    AND ertd3.parent_event_r_tree_data_id IS NULL   
   THEN erc1.erc_desc  
  WHEN ertd2.parent_event_r_tree_data_id IS NOT NULL   
    AND ertd3.parent_event_r_tree_data_id IS NULL   
   THEN erc2.erc_desc  
  WHEN ertd3.parent_event_r_tree_data_id IS NOT NULL   
   THEN erc3.erc_desc  
  ELSE 'Unknown'  
  END  
 FROM [dbo].event_reason_tree AS ert  
  --get the link to the reason tree data  
   left join [dbo].event_reason_tree_data AS ertd ON (ertd.tree_name_id = ert.tree_name_id)  
  --get the link to reason level 1  
   left join [dbo].event_reasons  AS er ON (er.event_reason_id = ertd.event_reason_id)  
  -- get the link to reason level 2  
   left join [dbo].event_reason_tree_data AS ertd1 ON (ertd1.parent_event_r_tree_data_id = ertd.event_reason_tree_data_id)  
   left join [dbo].event_reasons  AS er1 ON (er1.event_reason_id = ertd1.event_reason_id)  
  --get the link to reason level 3  
   left join [dbo].event_reason_tree_data AS ertd2 ON (ertd2.parent_event_r_tree_data_id = ertd1.event_reason_tree_data_id)  
   left join [dbo].event_reasons  AS er2 ON (er2.event_reason_id = ertd2.event_reason_id)  
  --get the link to reason level4  
   left join [dbo].event_reason_tree_data AS ertd3 ON (ertd3.parent_event_r_tree_data_id = ertd2.event_reason_tree_data_id)  
   left join [dbo].event_reasons  AS er3 ON (er3.event_reason_id = ertd3.event_reason_id)  
  --get the link to reason categories for reason level 1  
   left join [dbo].event_reason_category_data AS ercd ON (ercd. event_reason_tree_data_id =ertd.event_reason_tree_data_id)  
   left join [dbo].event_reason_catagories AS erc ON (erc.erc_id = ercd.erc_id)    
  --get the link to reason categories for reason level 2  
   left join [dbo].event_reason_category_data AS ercd1 ON (ercd1. event_reason_tree_data_id =ertd1.event_reason_tree_data_id)  
   left join [dbo].event_reason_catagories AS erc1 ON (erc1.erc_id = ercd1.erc_id)    
  --get the link to reason categories for reason level 3  
   left join [dbo].event_reason_category_data AS ercd2 ON (ercd2. event_reason_tree_data_id =ertd2.event_reason_tree_data_id)  
   left join [dbo].event_reason_catagories AS erc2 ON (erc2.erc_id = ercd2.erc_id)    
  --get the link to reason categories for reason level 4  
   left join [dbo].event_reason_category_data AS ercd3 ON (ercd3. event_reason_tree_data_id =ertd3.event_reason_tree_data_id)  
   left join [dbo].event_reason_catagories AS erc3 ON (erc3.erc_id = ercd3.erc_id)     
 WHERE  ertd. parent_event_r_tree_data_id IS null  
 ORDER BY tree_name,  
   [ReasonLevel1],  
   [ReasonLevel2],  
   [ReasonLevel3],  
   [ReasonLevel4],  
   [Reason Category]  
  
SET NOCOUNT OFF  
  
