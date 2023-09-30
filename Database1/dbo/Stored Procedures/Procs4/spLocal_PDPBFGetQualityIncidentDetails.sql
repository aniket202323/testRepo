




CREATE	PROCEDURE [dbo].[spLocal_PDPBFGetQualityIncidentDetails]
		@TransType		INT		= 0			-- 1: Last 24 hours, 0: Last 4 days
AS
-------------------------------------------------------------------------------
-- This SP retrieves the quality incident details mashup
--
--
-- Date         Version Build  Author								Notes
-- 30-Aug-2016  001     001    Alex Judkowicz (GE Digital)			Initial development
/*
exec spLocal_PDPBFGetQualityIncidentDetails 0
*/
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Declare variables
-------------------------------------------------------------------------------
DECLARE	@tOutput TABLE 
(
	Id				INT				IDENTITY(1,1)	NOT NULL,
	Label01Visible	BIT				NULL,
	Label01Value	VARCHAR(255)	NULL,
	Label02Visible	BIT				NULL,
	Label02Value	VARCHAR(255)	NULL,
	Label03Visible	BIT				NULL,
	Label03Value	VARCHAR(255)	NULL,
	Label04Visible	BIT				NULL,
	Label04Value	VARCHAR(255)	NULL,
	Label05Visible	BIT				NULL,
	Label05Value	VARCHAR(255)	NULL,
	Label06Visible	BIT				NULL,
	Label06Value	VARCHAR(255)	NULL,
	Label07Visible	BIT				NULL,
	Label07Value	VARCHAR(255)	NULL,
	Label08Visible	BIT				NULL,
	Label08Value	VARCHAR(255)	NULL,
	Label09Visible	BIT				NULL,
	Label09Value	VARCHAR(255)	NULL,
	Label10Visible	BIT				NULL,
	Label10Value	VARCHAR(255)	NULL,
	Label11Visible	BIT				NULL,
	Label11Value	VARCHAR(255)	NULL,
	Label12Visible	BIT				NULL,
	Label12Value	VARCHAR(255)	NULL,
	Label13Visible	BIT				NULL,
	Label13Value	VARCHAR(255)	NULL,
	Label14Visible	BIT				NULL,
	Label14Value	VARCHAR(255)	NULL,
	Label15Visible	BIT				NULL,
	Label15Value	VARCHAR(255)	NULL,
	Label16Visible	BIT				NULL,
	Label16Value	VARCHAR(255)	NULL,
	Label17Visible	BIT				NULL,
	Label17Value	VARCHAR(255)	NULL,
	Label18Visible	BIT				NULL,
	Label18Value	VARCHAR(255)	NULL,
	Label19Visible	BIT				NULL,
	Label19Value	VARCHAR(255)	NULL,
	Label20Visible	BIT				NULL,
	Label20Value	VARCHAR(255)	NULL,
	Label21Visible	BIT				NULL,
	Label21Value	VARCHAR(255)	NULL,
	Field01Value	VARCHAR(1024)	NULL,
	Field02Value	VARCHAR(1024)	NULL,
	Field03Value	VARCHAR(1024)	NULL,
	Field04Value	VARCHAR(1024)	NULL,
	Field05Value	VARCHAR(1024)	NULL,
	Field06Value	VARCHAR(1024)	NULL,
	Field07Value	VARCHAR(1024)	NULL,
	Field08Value	VARCHAR(1024)	NULL,
	Field09Value	VARCHAR(1024)	NULL,
	Field10Value	VARCHAR(1024)	NULL,
	Field11Value	VARCHAR(1024)	NULL,
	Field12Value	VARCHAR(1024)	NULL,
	Field13Value	VARCHAR(1024)	NULL,
	Field14Value	VARCHAR(1024)	NULL,
	Field15Value	VARCHAR(1024)	NULL,
	Field16Value	VARCHAR(1024)	NULL,
	Field17Value	VARCHAR(1024)	NULL,
	Field18Value	VARCHAR(1024)	NULL,
	Field19Value	VARCHAR(1024)	NULL,
	Field20Value	VARCHAR(1024)	NULL,
	Field21Value	VARCHAR(1024)	NULL
)
-------------------------------------------------------------------------------
-- Site-specific logic
-------------------------------------------------------------------------------
INSERT	@tOutput (Field01Value)
		VALUES ('Disabled')

/*
INSERT	@tOutput (Field01Value,Field02Value,Field03Value,Field04Value,Field05Value,
		Field06Value,Field07Value,Field08Value,Field09Value,Field10Value,
		Field11Value,Field12Value,Field13Value,Field14Value,Field15Value,
		Field16Value,Field17Value,Field18Value,Field19Value,Field20Value,
		Field21Value)
		VALUES	('Value01', 'Value02', 'Value03', 'Value04', 'Value05', 
				 'Value06', 'Value07', 'Value08', 'Value09', 'Value10', 
				'Value11', 'Value12', 'Value13', 'Value14', 'Value15', 
				'Value16', 'Value17', 'Value18', 'Value19', 'Value20', 
				'Value21')

INSERT	@tOutput (Field01Value,Field02Value,Field03Value,Field04Value,Field05Value,
		Field06Value,Field07Value,Field08Value,Field09Value,Field10Value,
		Field11Value,Field12Value,Field13Value,Field14Value,Field15Value,
		Field16Value,Field17Value,Field18Value,Field19Value,Field20Value,
		Field21Value)
		VALUES	('Value101', 'Value102', 'Value103', 'Value104', 'Value105', 
				 'Value106', 'Value107', 'Value108', 'Value109', 'Value110', 
				'Value111', 'Value112', 'Value113', 'Value114', 'Value115', 
				'Value116', 'Value117', 'Value118', 'Value119', 'Value120', 
				 'Value121')
*/
UPDATE	@TOutput 
		SET	Label01Visible = 1,
			Label02Visible = 1,
			Label03Visible = 1,
			Label04Visible = 1,
			Label05Visible = 1,
			Label06Visible = 1,
			Label07Visible = 1,
			Label08Visible = 1,
			Label09Visible = 1,
			Label10Visible = 1,
			Label11Visible = 1,
			Label12Visible = 1,
			Label13Visible = 1,
			Label14Visible = 1,
			Label15Visible = 1,
			Label16Visible = 1,
			Label17Visible = 1,
			Label18Visible = 1,
			Label19Visible = 1,
			Label20Visible = 1,
			Label21Visible = 1
		
UPDATE	@TOutput 
		SET	Label01Value = 'Label01',
			Label02Value = 'Label02',
			Label03Value = 'Label03',
			Label04Value = 'Label04',
			Label05Value = 'Label05',
			Label06Value = 'Label06',
			Label07Value = 'Label07',
			Label08Value = 'Label08',
			Label09Value = 'Label09',
			Label10Value = 'Label10',
			Label11Value = 'Label11',
			Label12Value = 'Label12',
			Label13Value = 'Label13',
			Label14Value = 'Label14',
			Label15Value = 'Label15',
			Label16Value = 'Label16',
			Label17Value = 'Label17',
			Label18Value = 'Label18',
			Label19Value = 'Label191',
			Label20Value = 'Label20',
			Label21Value = 'Label21'

-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------
SELECT	Id,
		Label01Visible,
		Label01Value,
		Label02Visible,
		Label02Value,
		Label03Visible,
		Label03Value,
		Label04Visible,
		Label04Value,
		Label05Visible,
		Label05Value,
		Label06Visible,
		Label06Value,
		Label07Visible,
		Label07Value,
		Label08Visible,
		Label08Value,
		Label09Visible,
		Label09Value,
		Label10Visible,
		Label10Value,
		Label11Visible,
		Label11Value,
		Label12Visible,
		Label12Value,
		Label13Visible,
		Label13Value,
		Label14Visible,
		Label14Value,
		Label15Visible,
		Label15Value,
		Label16Visible,
		Label16Value,
		Label17Visible,
		Label17Value,
		Label18Visible,
		Label18Value,
		Label19Visible,
		Label19Value,
		Label20Visible,
		Label20Value,
		Label21Visible,
		Label21Value,
		Field01Value,
		Field02Value,
		Field03Value,
		Field04Value,
		Field05Value,
		Field06Value,
		Field07Value,
		Field08Value,
		Field09Value,
		Field10Value,
		Field11Value,
		Field12Value,
		Field13Value,
		Field14Value,
		Field15Value,
		Field16Value,
		Field17Value,
		Field18Value,
		Field19Value,
		Field20Value,
		Field21Value
		FROM	@tOutput
		ORDER
		BY		Id

