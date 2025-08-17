import Link from 'next/link'

export default function HomePage() {
  return (
    <div className='flex min-h-screen flex-col items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800'>
      <div className='mx-auto max-w-md text-center'>
        <h1 className='mb-4 text-4xl font-bold tracking-tight text-gray-900 dark:text-white'>
          Enterprise Expense System
        </h1>
        <p className='mb-8 text-lg text-gray-600 dark:text-gray-300'>
          Modern expense management system for enterprises
        </p>
        
        <div className='space-y-4'>
          <Link
            href='/auth/login'
            className='block w-full rounded-lg bg-blue-600 px-6 py-3 text-white font-medium hover:bg-blue-700 transition-colors'
          >
            Get Started
          </Link>
          
          <div className='text-sm text-gray-500 dark:text-gray-400'>
            Learn more about our{' '}
            <Link href='/features' className='text-blue-600 hover:underline'>
              features
            </Link>
          </div>
        </div>
      </div>
      
      <div className='mt-16 text-center'>
        <div className='text-sm text-gray-500 dark:text-gray-400'>
          Status: Development Preview
        </div>
        <div className='mt-2 flex items-center justify-center space-x-4 text-xs text-gray-400'>
          <span>🚀 Auth Service</span>
          <span>🎨 Frontend</span>
          <span>🐳 Docker</span>
          <span>⚡ Next.js 14</span>
        </div>
      </div>
    </div>
  )
}