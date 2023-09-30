CREATE TABLE [dbo].[Dashboard_Dialogues] (
    [Dashboard_Dialogue_ID]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Dialogue_Name] VARCHAR (100)  NOT NULL,
    [External_Address]        BIT            NOT NULL,
    [Locked]                  BIT            NULL,
    [Parameter_Count]         INT            NULL,
    [URL]                     VARCHAR (1000) NULL,
    [version]                 INT            NULL,
    CONSTRAINT [PK_Dashboard_Dialogues] PRIMARY KEY NONCLUSTERED ([Dashboard_Dialogue_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Dialogues]
    ON [dbo].[Dashboard_Dialogues]([Dashboard_Dialogue_ID] ASC);

