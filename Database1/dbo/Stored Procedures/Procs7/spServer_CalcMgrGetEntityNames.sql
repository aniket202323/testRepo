﻿CREATE PROCEDURE dbo.spServer_CalcMgrGetEntityNames
AS
select calc_input_entity_id, Entity_Name from calculation_input_entities
order by calc_input_entity_id
