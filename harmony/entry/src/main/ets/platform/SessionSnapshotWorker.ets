import { taskpool } from '@kit.ArkTS';
import { encodeSessionSnapshot, SNAPSHOT_BUDGET_BYTES } from '../core/SessionSnapshot';

@Concurrent
function pack(sessions: Record<string, Object>[], conversations: Record<string, Object>[],
  heldActions: Record<string, Object>[], sidebarConfig?: string): string {
  return encodeSessionSnapshot(sessions, conversations, heldActions, SNAPSHOT_BUDGET_BYTES, sidebarConfig);
}

export async function packSessionSnapshot(sessions: Record<string, Object>[], conversations: Record<string, Object>[],
  heldActions: Record<string, Object>[], sidebarConfig?: string): Promise<string> {
  const task = sidebarConfig === undefined ? new taskpool.Task(pack, sessions, conversations, heldActions) :
    new taskpool.Task(pack, sessions, conversations, heldActions, sidebarConfig);
  return await taskpool.execute(task) as string;
}
