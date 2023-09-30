CREATE TABLE [dbo].[Dashboard_Template_Dialogue_Parameters] (
    [Dashboard_Template_Dialogue_Parameter_ID] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Dialogue_ID]                    INT NOT NULL,
    [Dashboard_Template_Parameter_ID]          INT NOT NULL,
    CONSTRAINT [PK_Dashboard_Template_Dialogue_Parameters] PRIMARY KEY NONCLUSTERED ([Dashboard_Template_Dialogue_Parameter_ID] ASC, [Dashboard_Dialogue_ID] ASC, [Dashboard_Template_Parameter_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Template_Dialogue_Parameters]
    ON [dbo].[Dashboard_Template_Dialogue_Parameters]([Dashboard_Template_Dialogue_Parameter_ID] ASC);

