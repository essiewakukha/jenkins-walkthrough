import { render, screen, within } from '@testing-library/react'
import App from './App'

describe('App', () => {
  it('renders the main hero content and contact call to action', () => {
    render(<App />)

    expect(
      screen.getByRole('heading', {
        name: /one focused page for your next launch/i,
      }),
    ).toBeInTheDocument()

    expect(
      screen.getByRole('link', { name: /book a strategy call/i }),
    ).toHaveAttribute('href', '#contact')

    expect(
      screen.getByRole('link', { name: /hello@northstar.test/i }),
    ).toHaveAttribute('href', 'mailto:hello@northstar.test')
  })

  it('renders the three feature cards', () => {
    render(<App />)

    const servicesSection = screen.getByRole('heading', {
      name: /a small site with real structure behind it/i,
    }).closest('section')

    expect(servicesSection).not.toBeNull()

    const scopedQueries = within(servicesSection)

    expect(
      scopedQueries.getByRole('heading', { name: /clarity before code/i }),
    ).toBeInTheDocument()
    expect(
      scopedQueries.getByRole('heading', { name: /fast design systems/i }),
    ).toBeInTheDocument()
    expect(
      scopedQueries.getByRole('heading', { name: /measured handoff/i }),
    ).toBeInTheDocument()
  })
})