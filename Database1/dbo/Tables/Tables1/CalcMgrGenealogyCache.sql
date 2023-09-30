CREATE TABLE [dbo].[CalcMgrGenealogyCache] (
    [ComponentId]     INT      NULL,
    [EventId]         INT      NULL,
    [EventUnit]       INT      NULL,
    [GenealogyLevel]  INT      NULL,
    [OriginalEventId] INT      NULL,
    [TimeStamp]       DATETIME NULL
);


GO
CREATE NONCLUSTERED INDEX [CalcMgrGenealogyCache_IDX_EventId]
    ON [dbo].[CalcMgrGenealogyCache]([OriginalEventId] ASC);

