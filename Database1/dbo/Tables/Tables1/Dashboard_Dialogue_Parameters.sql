CREATE TABLE [dbo].[Dashboard_Dialogue_Parameters] (
    [Dashboard_Dialogue_Parameter_ID] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Dialogue_ID]           INT NOT NULL,
    [Dashboard_Parameter_Type_Id]     INT NOT NULL,
    [default_dialogue]                BIT CONSTRAINT [DF__dashboard__defau__54B751CD] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Dashboard_Dialogue_Parameters] PRIMARY KEY NONCLUSTERED ([Dashboard_Dialogue_Parameter_ID] ASC, [Dashboard_Dialogue_ID] ASC, [Dashboard_Parameter_Type_Id] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Dialogue_Parameters]
    ON [dbo].[Dashboard_Dialogue_Parameters]([Dashboard_Dialogue_Parameter_ID] ASC);

