import { beforeEach, describe, expect, it, vi } from "vitest";
import axios from "axios";
import type * as WorkshopsService from "../services/workshops";
import type * as SessionsService from "../services/sessions";
import type * as AttendeesService from "../services/attendees";
import type * as RegistrationsService from "../services/registrations";
import type * as DashboardService from "../services/dashboard";
import type * as ApiService from "../services/api";

let workshops: typeof WorkshopsService;
let sessions: typeof SessionsService;
let attendees: typeof AttendeesService;
let registrations: typeof RegistrationsService;
let dashboard: typeof DashboardService;
let api: typeof ApiService;

beforeEach(async () => {
  vi.resetModules();
  workshops = await import("../services/workshops");
  sessions = await import("../services/sessions");
  attendees = await import("../services/attendees");
  registrations = await import("../services/registrations");
  dashboard = await import("../services/dashboard");
  api = await import("../services/api");
});

describe("getWorkshops", () => {
  it("returns only active workshops that have at least one session by default", async () => {
    const result = await workshops.getWorkshops();

    expect(result.data.map((w) => w.id)).toEqual([1, 2]);
    expect(result.pagination.count).toBe(2);
    expect(result.pagination.pages).toBe(1);
  });

  it("includes inactive workshops when activeOnly is false", async () => {
    const result = await workshops.getWorkshops(1, 5, false);

    expect(result.data).toHaveLength(3);
    expect(result.pagination.count).toBe(3);
  });

  it("paginates results", async () => {
    const result = await workshops.getWorkshops(2, 1, false);

    expect(result.data).toHaveLength(1);
    expect(result.pagination.page).toBe(2);
    expect(result.pagination.limit).toBe(1);
    expect(result.pagination.pages).toBe(3);
    expect(result.pagination.next).toBe(3);
    expect(result.pagination.prev).toBe(1);
  });
});

describe("createWorkshop", () => {
  it("creates a workshop and prepends it to the list", async () => {
    const workshop = await workshops.createWorkshop({
      title: "Testing Workshop",
      description: "A test workshop",
      topic: "Testing",
      active: true,
    });

    expect(workshop).toMatchObject({
      title: "Testing Workshop",
      topic: "Testing",
      active: true,
    });
    expect(workshop.id).toEqual(expect.any(Number));

    const all = await workshops.getWorkshops(1, 10, false);
    expect(all.data[0]).toEqual(workshop);
  });
});

describe("getWorkshopById", () => {
  it("returns the matching workshop", async () => {
    const workshop = await workshops.getWorkshopById(1);
    expect(workshop?.title).toBe("Rails APIs for Modern Teams");
  });

  it("returns undefined when not found", async () => {
    const workshop = await workshops.getWorkshopById(999999);
    expect(workshop).toBeUndefined();
  });
});

describe("updateWorkshop", () => {
  it("updates an existing workshop", async () => {
    const updated = await workshops.updateWorkshop(1, {
      title: "Updated title",
      description: "Updated description",
      topic: "Updated",
      active: false,
    });

    expect(updated).toMatchObject({
      id: 1,
      title: "Updated title",
      active: false,
    });
  });

  it("throws when the workshop does not exist", async () => {
    await expect(
      workshops.updateWorkshop(999999, {
        title: "x",
        description: "x",
        topic: "x",
        active: true,
      }),
    ).rejects.toThrow("Workshop not found");
  });
});

describe("getSessionsForWorkshop", () => {
  it("returns sessions for the given workshop", async () => {
    const result = await sessions.getSessionsForWorkshop(1);

    expect(result.data).toHaveLength(2);
    expect(result.data.every((s) => s.workshopId === 1)).toBe(true);
  });

  it("paginates sessions", async () => {
    const result = await sessions.getSessionsForWorkshop(1, 1, 1);

    expect(result.data).toHaveLength(1);
    expect(result.pagination.pages).toBe(2);
  });
});

describe("createSession", () => {
  it("creates a session and makes it retrievable", async () => {
    const session = await sessions.createSession({
      workshopId: 2,
      startsAt: "2026-09-01T09:00:00.000Z",
      endsAt: "2026-09-01T11:00:00.000Z",
      capacity: 5,
      status: "scheduled",
    });

    const found = await sessions.getSessionById(session.id);
    expect(found).toEqual(session);
  });
});

describe("getSessionById", () => {
  it("returns undefined for an unknown session", async () => {
    const session = await sessions.getSessionById(999999);
    expect(session).toBeUndefined();
  });
});

describe("getAttendees", () => {
  it("returns a copy of the attendee list", async () => {
    const all = await attendees.getAttendees();
    expect(all).toHaveLength(2);

    all.push({ id: 999, name: "Injected", email: "injected@example.com" });

    const attendeesAgain = await attendees.getAttendees();
    expect(attendeesAgain).toHaveLength(2);
  });
});

describe("getAttendeeByEmail", () => {
  it("finds an attendee case-insensitively", async () => {
    const attendee = await attendees.getAttendeeByEmail("ANA@EXAMPLE.COM");
    expect(attendee?.name).toBe("Ana García");
  });

  it("returns undefined when no attendee matches", async () => {
    const attendee = await attendees.getAttendeeByEmail("nobody@example.com");
    expect(attendee).toBeUndefined();
  });
});

describe("createAttendee", () => {
  it("creates a new attendee", async () => {
    const attendee = await attendees.createAttendee(
      "New Person",
      "new@example.com",
    );
    expect(attendee).toMatchObject({
      name: "New Person",
      email: "new@example.com",
    });

    const all = await attendees.getAttendees();
    expect(all).toHaveLength(3);
  });

  it("returns the existing attendee instead of duplicating", async () => {
    const attendee = await attendees.createAttendee(
      "Ana Duplicate",
      "ANA@example.com",
    );
    expect(attendee.id).toBe(1);
    expect(attendee.name).toBe("Ana García");

    const all = await attendees.getAttendees();
    expect(all).toHaveLength(2);
  });
});

describe("getAttendeeByIdFromApi", () => {
  it("returns the attendee", async () => {
    vi.spyOn(api.apiClient, "get").mockResolvedValue({
      data: { data: { id: 7, name: "Ana García", email: "ana@example.com" } },
    });

    const result = await attendees.getAttendeeByIdFromApi(7);

    expect(api.apiClient.get).toHaveBeenCalledWith("/attendees/7");
    expect(result).toEqual({
      id: 7,
      name: "Ana García",
      email: "ana@example.com",
    });
  });

  it("returns undefined on a 404", async () => {
    const axiosError = Object.assign(new Error("Not Found"), {
      isAxiosError: true,
      response: { status: 404, data: {} },
    });
    vi.spyOn(api.apiClient, "get").mockRejectedValue(axiosError);
    vi.spyOn(axios, "isAxiosError").mockReturnValue(true);

    const result = await attendees.getAttendeeByIdFromApi(999999);

    expect(result).toBeUndefined();
  });

  it("re-throws non-404 errors", async () => {
    const axiosError = Object.assign(new Error("Server error"), {
      isAxiosError: true,
      response: { status: 500, data: {} },
    });
    vi.spyOn(api.apiClient, "get").mockRejectedValue(axiosError);
    vi.spyOn(axios, "isAxiosError").mockReturnValue(true);

    await expect(attendees.getAttendeeByIdFromApi(7)).rejects.toBe(axiosError);
  });
});

describe("getAttendeeRegistrationsFromApi", () => {
  it("fetches a page of the attendee's registrations and maps session/workshop details", async () => {
    const responseBody = {
      message: "Registrations returned correctly",
      status: "ok",
      data: [
        {
          id: 42,
          status: "confirmed",
          hold_expires_at: null,
          confirmed_at: "2026-07-29T10:00:00.000Z",
          cancelled_at: null,
          session: {
            id: 101,
            starts_at: "2026-08-01T09:00:00.000Z",
            ends_at: "2026-08-01T11:00:00.000Z",
            capacity: 5,
            status: "scheduled",
            workshop: {
              id: 1,
              title: "Rails APIs for Modern Teams",
              topic: "Rails",
            },
          },
        },
      ],
      pagination: {
        page: 1,
        pages: 1,
        count: 1,
        limit: 10,
        next: null,
        prev: null,
      },
      status_counts: {
        held: 0,
        confirmed: 1,
        waitlisted: 0,
        cancelled: 0,
        expired: 0,
      },
    };
    vi.spyOn(api.apiClient, "get").mockResolvedValue({ data: responseBody });

    const result = await attendees.getAttendeeRegistrationsFromApi(7);

    expect(api.apiClient.get).toHaveBeenCalledWith(
      "/attendees/7/registrations",
      { params: { page: 1, per_page: 10 } },
    );
    expect(result.data).toEqual([
      {
        id: 42,
        status: "confirmed",
        holdExpiresAt: undefined,
        confirmedAt: "2026-07-29T10:00:00.000Z",
        cancelledAt: undefined,
        session: {
          id: 101,
          startsAt: "2026-08-01T09:00:00.000Z",
          endsAt: "2026-08-01T11:00:00.000Z",
          capacity: 5,
          status: "scheduled",
          workshop: {
            id: 1,
            title: "Rails APIs for Modern Teams",
            topic: "Rails",
          },
        },
      },
    ]);
    expect(result.pagination).toEqual(responseBody.pagination);
    expect(result.statusCounts).toEqual({
      held: 0,
      confirmed: 1,
      waitlisted: 0,
      cancelled: 0,
      expired: 0,
    });
  });

  it("handles a missing session gracefully", async () => {
    vi.spyOn(api.apiClient, "get").mockResolvedValue({
      data: {
        message: null,
        status: "ok",
        data: [
          {
            id: 1,
            status: "cancelled",
            hold_expires_at: null,
            confirmed_at: null,
            cancelled_at: null,
            session: null,
          },
        ],
        pagination: {
          page: 1,
          pages: 1,
          count: 1,
          limit: 10,
          next: null,
          prev: null,
        },
        status_counts: {
          held: 0,
          confirmed: 0,
          waitlisted: 0,
          cancelled: 1,
          expired: 0,
        },
      },
    });

    const result = await attendees.getAttendeeRegistrationsFromApi(7);

    expect(result.data).toEqual([
      {
        id: 1,
        status: "cancelled",
        holdExpiresAt: undefined,
        confirmedAt: undefined,
        cancelledAt: undefined,
        session: undefined,
      },
    ]);
    expect(result.statusCounts).toEqual({
      held: 0,
      confirmed: 0,
      waitlisted: 0,
      cancelled: 1,
      expired: 0,
    });
  });
});

describe("getSessionAttendeeStatuses", () => {
  it("returns attendee info and status for each registration", async () => {
    const statuses = await sessions.getSessionAttendeeStatuses(101);

    expect(statuses).toEqual(
      expect.arrayContaining([
        { name: "Ana García", email: "ana@example.com", status: "confirmed" },
        { name: "Luis Pérez", email: "luis@example.com", status: "held" },
      ]),
    );
  });

  it("returns an empty list for a session with no registrations", async () => {
    const statuses = await sessions.getSessionAttendeeStatuses(103);
    expect(statuses).toEqual([]);
  });
});

describe("createRegistration", () => {
  it("holds the registration when capacity is available", async () => {
    const registration = await registrations.createRegistration({
      attendeeName: "New Attendee",
      attendeeEmail: "new-attendee@example.com",
      sessionId: 103,
    });

    expect(registration.status).toBe("held");
    expect(registration.holdExpiresAt).toEqual(expect.any(String));
  });

  it("waitlists the registration when the session is full", async () => {
    await registrations.createRegistration({
      attendeeName: "First Attendee",
      attendeeEmail: "first@example.com",
      sessionId: 103,
    });

    const second = await registrations.createRegistration({
      attendeeName: "Second Attendee",
      attendeeEmail: "second@example.com",
      sessionId: 103,
    });

    expect(second.status).toBe("waitlisted");
    expect(second.holdExpiresAt).toBeUndefined();
  });

  it("throws when the attendee already has an active registration for the session", async () => {
    await expect(
      registrations.createRegistration({
        attendeeName: "Ana García",
        attendeeEmail: "ana@example.com",
        sessionId: 101,
      }),
    ).rejects.toThrow(
      "The attendee already has an active registration for this session.",
    );
  });

  it("throws when the session does not exist", async () => {
    await expect(
      registrations.createRegistration({
        attendeeName: "Someone",
        attendeeEmail: "someone@example.com",
        sessionId: 999999,
      }),
    ).rejects.toThrow("Session not found");
  });

  it("reuses an existing attendee instead of creating a duplicate", async () => {
    await registrations.createRegistration({
      attendeeName: "Luis Pérez",
      attendeeEmail: "luis@example.com",
      sessionId: 103,
    });

    const all = await attendees.getAttendees();
    expect(all).toHaveLength(2);
  });
});

describe("confirmRegistration", () => {
  it("confirms a held registration", async () => {
    const confirmed = await registrations.confirmRegistration(5002);

    expect(confirmed.status).toBe("confirmed");
    expect(confirmed.confirmedAt).toEqual(expect.any(String));
    expect(confirmed.holdExpiresAt).toBeUndefined();
  });

  it("throws when the registration does not exist", async () => {
    await expect(registrations.confirmRegistration(999999)).rejects.toThrow(
      "Registration not found",
    );
  });
});

describe("cancelRegistration", () => {
  it("cancels a registration", async () => {
    const cancelled = await registrations.cancelRegistration(5002);

    expect(cancelled.status).toBe("cancelled");
    expect(cancelled.cancelledAt).toEqual(expect.any(String));
    expect(cancelled.holdExpiresAt).toBeUndefined();
  });

  it("throws when the registration does not exist", async () => {
    await expect(registrations.cancelRegistration(999999)).rejects.toThrow(
      "Registration not found",
    );
  });

  it("promotes the earliest waitlisted registration when a slot frees up", async () => {
    const held = await registrations.createRegistration({
      attendeeName: "Held Attendee",
      attendeeEmail: "held@example.com",
      sessionId: 103,
    });
    const waitlisted = await registrations.createRegistration({
      attendeeName: "Waitlisted Attendee",
      attendeeEmail: "waitlisted@example.com",
      sessionId: 103,
    });
    expect(waitlisted.status).toBe("waitlisted");

    await registrations.cancelRegistration(held.id);

    const statuses = await sessions.getSessionAttendeeStatuses(103);
    const promoted = statuses.find((s) => s.email === "waitlisted@example.com");
    expect(promoted?.status).toBe("held");
  });

  it("does not promote anyone when there is no waitlist", async () => {
    await registrations.cancelRegistration(5002);

    const statuses = await sessions.getSessionAttendeeStatuses(101);
    expect(statuses.find((s) => s.email === "ana@example.com")?.status).toBe(
      "confirmed",
    );
    expect(statuses.some((s) => s.status === "held")).toBe(false);
  });
});

describe("getRegistrationsForAttendee", () => {
  it("returns all registrations for an attendee", async () => {
    const result = await registrations.getRegistrationsForAttendee(2);
    expect(result).toHaveLength(2);
  });

  it("returns an empty list when the attendee has no registrations", async () => {
    const result = await registrations.getRegistrationsForAttendee(999999);
    expect(result).toEqual([]);
  });
});

describe("getRegistrationHistoryByEmail", () => {
  it("returns the attendee and their registrations", async () => {
    const history =
      await registrations.getRegistrationHistoryByEmail("luis@example.com");

    expect(history?.attendee.name).toBe("Luis Pérez");
    expect(history?.registrations).toHaveLength(2);
  });

  it("returns undefined for an unknown email", async () => {
    const history =
      await registrations.getRegistrationHistoryByEmail("nobody@example.com");
    expect(history).toBeUndefined();
  });
});

describe("getDashboardWorkshops", () => {
  it("fetches and maps active workshops with their current/next session", async () => {
    const mockResponse = {
      message: "ok",
      status: "ok",
      data: [
        {
          id: 1,
          title: "Rails APIs for Modern Teams",
          topic: "Rails",
          description: "desc",
          current_session: {
            id: 101,
            starts_at: "2026-08-01T09:00:00Z",
            ends_at: "2026-08-01T11:00:00Z",
            capacity: 3,
            available_seats: 2,
            in_progress: false,
          },
        },
        {
          id: 2,
          title: "No Sessions Workshop",
          topic: "Vue",
          description: "desc",
          current_session: null,
        },
      ],
    };
    vi.spyOn(api.apiClient, "get").mockResolvedValue({ data: mockResponse });

    const result = await dashboard.getDashboardWorkshops();

    expect(api.apiClient.get).toHaveBeenCalledWith("/dashboard");
    expect(result).toEqual([
      {
        id: 1,
        title: "Rails APIs for Modern Teams",
        topic: "Rails",
        description: "desc",
        currentSession: {
          id: 101,
          startsAt: "2026-08-01T09:00:00Z",
          endsAt: "2026-08-01T11:00:00Z",
          capacity: 3,
          availableSeats: 2,
          inProgress: false,
        },
      },
      {
        id: 2,
        title: "No Sessions Workshop",
        topic: "Vue",
        description: "desc",
        currentSession: null,
      },
    ]);
  });
});

describe("getWorkshopDashboardMetrics", () => {
  it("fetches and maps a single workshop dashboard metrics payload", async () => {
    const mockResponse = {
      message: "ok",
      status: "ok",
      data: {
        workshop_id: 1,
        workshop_title: "Rails APIs for Modern Teams",
        upcoming_sessions: 2,
        held_registrations: 1,
        confirmed_registrations: 3,
        waitlisted_registrations: 1,
        expired_holds_today: 0,
        full_sessions: 1,
        top_waitlisted_sessions: [
          {
            session_id: 102,
            starts_at: "2026-08-02T15:00:00Z",
            waitlist_size: 1,
          },
        ],
      },
    };
    vi.spyOn(api.apiClient, "get").mockResolvedValue({ data: mockResponse });

    const metrics = await dashboard.getWorkshopDashboardMetrics(1);

    expect(api.apiClient.get).toHaveBeenCalledWith("/workshops/1/dashboard");
    expect(metrics).toEqual({
      workshopId: 1,
      workshopTitle: "Rails APIs for Modern Teams",
      upcomingSessions: 2,
      heldRegistrations: 1,
      confirmedRegistrations: 3,
      waitlistedRegistrations: 1,
      expiredHoldsToday: 0,
      fullSessions: 1,
      topWaitlistedSessions: [
        { sessionId: 102, startsAt: "2026-08-02T15:00:00Z", waitlistSize: 1 },
      ],
    });
  });
});

describe("getWorkshopsFromApi", () => {
  it("fetches workshops from the backend API", async () => {
    const mockData = [
      { id: 1, title: "From API", description: "", topic: "", active: true },
    ];
    vi.spyOn(api.apiClient, "get").mockResolvedValue({ data: mockData });

    const result = await workshops.getWorkshopsFromApi();

    expect(result).toEqual(mockData);
    expect(api.apiClient.get).toHaveBeenCalledWith("/workshops");
  });
});
