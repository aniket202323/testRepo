CREATE PROCEDURE dbo.spALM_GetSounds
as
select binary_id, binary_desc from binaries
where field_type_id = 25
order by binary_desc
