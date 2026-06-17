export type TicketStatus = 'pending' | 'in-progress' | 'resolved';
export type TicketCategory = 'system-issue' | 'data-integrity' | 'performance' | 'ui-ux' | 'integration' | 'other';

export interface StatusHistory {
  status: TicketStatus; timestamp: string; updatedBy: string; note?: string;
}

export interface Ticket {
  id: string; ticketId: string; title: string; description: string;
  reporterUserId: string; category: TicketCategory; orderOfImpact: number;
  isNewRequirement: boolean; status: TicketStatus; statusHistory: StatusHistory[];
  assignedTo?: string; resolutionNotes?: string; createdAt: string;
  updatedAt: string; resolvedAt?: string; isRecalled: boolean;
  recalledAt?: string; recallReason?: string;
}

export const StatusColors = { 'pending': 'danger', 'in-progress': 'warning', 'resolved': 'success' } as const;
export const StatusLabels = { 'pending': 'Pending', 'in-progress': 'In Progress', 'resolved': 'Resolved' } as const;
export const CategoryLabels = {
  'system-issue': 'System Issue', 'data-integrity': 'Data Integrity',
  'performance': 'Performance', 'ui-ux': 'UI/UX',
  'integration': 'Integration', 'other': 'Other'
} as const;
